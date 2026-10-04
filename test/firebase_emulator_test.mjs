import assert from 'node:assert/strict';

const project = 'demo-academya';
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
for (const host of [authHost, firestoreHost]) {
  assert.match(host ?? '', /^(127\.0\.0\.1|localhost):\d+$/, 'Only local Firebase emulators are allowed');
}
assert.equal(process.env.GCLOUD_PROJECT, project);
const documents = `projects/${project}/databases/(default)/documents`;
const firestoreUrl = `http://${firestoreHost}/v1/${documents}`;
let checks = 0;

async function request(url, body, token) {
  const response = await fetch(url, {
    method: body ? 'POST' : 'GET',
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  return { status: response.status, data: await response.json() };
}

function ok(result, label) {
  assert.equal(result.status, 200, `${label}: ${JSON.stringify(result.data)}`);
  checks++;
}

function denied(result, label) {
  assert.equal(result.status, 403, `${label}: ${JSON.stringify(result.data)}`);
  checks++;
}

async function auth(method, body) {
  return request(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:${method}?key=local-test`, body);
}

function fields(data) {
  return Object.fromEntries(Object.entries(data).map(([key, value]) => [
    key, Array.isArray(value)
      ? { arrayValue: { values: value.map((item) => ({ stringValue: item })) } }
      : { stringValue: value },
  ]));
}

async function write(path, data, token, transforms = []) {
  return request(`${firestoreUrl}:commit`, {
    writes: [{
      update: { name: `${documents}/${path}`, fields: fields(data) },
      ...(transforms.length ? { updateTransforms: transforms } : {}),
    }],
  }, token);
}

const ownerAccount = await auth('signUp', {
  email: 'owner@example.com', password: 'Testing123', returnSecureToken: true,
});
ok(ownerAccount, 'Create email/password account');
const owner = ownerAccount.data;
const memberAccount = await auth('signUp', {
  email: 'member@example.com', password: 'Testing123', returnSecureToken: true,
});
ok(memberAccount, 'Create second account');
const member = memberAccount.data;
const strangerAccount = await auth('signUp', {
  email: 'stranger@example.com', password: 'Testing123', returnSecureToken: true,
});
ok(strangerAccount, 'Create non-member account');
const stranger = strangerAccount.data;

ok(await auth('update', { idToken: owner.idToken, displayName: 'Maria Silva', returnSecureToken: true }),
  'Persist display name in Auth');
const login = await auth('signInWithPassword', {
  email: owner.email, password: 'Testing123', returnSecureToken: true,
});
ok(login, 'Login after account creation');
assert.equal(login.data.localId, owner.localId);
checks++;
const invalidLogin = await auth('signInWithPassword', {
  email: owner.email, password: 'Incorrect123', returnSecureToken: true,
});
assert.equal(invalidLogin.status, 400);
checks++;
const duplicate = await auth('signUp', {
  email: owner.email, password: 'Testing123', returnSecureToken: true,
});
assert.equal(duplicate.status, 400);
checks++;

const profile = { fullName: 'Maria Silva', email: owner.email };
const timestamp = [{ fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' }];
ok(await write(`users/${owner.localId}`, profile, owner.idToken, timestamp), 'Save own profile');
ok(await request(`${firestoreUrl}/users/${owner.localId}`, null, owner.idToken), 'Read own profile');
denied(await request(`${firestoreUrl}/users/${owner.localId}`, null, member.idToken), 'Deny other profile read');
denied(await write(`users/${owner.localId}`, profile, member.idToken, timestamp), 'Deny other profile write');
denied(await write(`users/${owner.localId}`, { ...profile, password: 'NeverStoreThis' }, owner.idToken, timestamp),
  'Deny password field in Firestore');

const schoolClass = {
  id: 'class-test', name: 'Turma Firebase', creatorId: owner.localId,
  creatorName: 'Maria Silva', joinCode: 'ABC234', type: 'classroom', memberIds: [owner.localId],
};
ok(await write('classes/class-test', schoolClass, owner.idToken), 'Create class with Firebase UID');
denied(await write('classes/spoofed', { ...schoolClass, id: 'spoofed' }, member.idToken),
  'Deny class with another creator UID');
ok(await write('classes/class-test', {
  ...schoolClass, memberIds: [owner.localId, member.localId],
}, member.idToken), 'Member can add only own UID');
denied(await write('classes/class-test', {
  ...schoolClass, memberIds: [member.localId],
}, member.idToken), 'Deny removing creator from members');
denied(await write('classes/class-test', {
  ...schoolClass, creatorId: member.localId, memberIds: [owner.localId, member.localId],
}, member.idToken), 'Deny changing ownership');

const publication = {
  id: 'post-test', classId: 'class-test', title: 'Aviso', description: 'Conteudo persistente',
  type: 'notice', authorName: 'Maria Silva', createdAt: new Date().toISOString(),
};
ok(await write('classes/class-test/publications/post-test', publication, owner.idToken),
  'Creator can publish');
ok(await request(`${firestoreUrl}/classes/class-test/publications/post-test`, null, member.idToken),
  'Member can read publication');
denied(await request(`${firestoreUrl}/classes/class-test/publications/post-test`, null, stranger.idToken),
  'Deny non-member reading publication');
denied(await write('classes/class-test/publications/member-post', {
  ...publication, id: 'member-post',
}, member.idToken), 'Deny publishing as non-creator');
denied(await write('classes/class-test/publications/long-post', {
  ...publication, id: 'long-post', description: 'a'.repeat(901),
}, owner.idToken), 'Enforce publication length');
denied(await request(`${firestoreUrl}/classes/class-test`), 'Deny unauthenticated access');
const anonymousAccount = await auth('signUp', { returnSecureToken: true });
ok(anonymousAccount, 'Create legacy anonymous session for denial check');
denied(await request(`${firestoreUrl}/classes/class-test`, null, anonymousAccount.data.idToken),
  'Deny legacy anonymous session');
console.log(`${checks} Firebase emulator checks passed. No production project was accessed.`);

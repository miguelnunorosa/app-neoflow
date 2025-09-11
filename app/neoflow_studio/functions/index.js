/**
 * Firebase Functions v2 — Provisionamento automático de utilizadores
 * Cria usersAccounts/{uid} quando um utilizador é criado no Auth
 */

const { setGlobalOptions } = require("firebase-functions");
const { onUserCreated, onUserDeleted } = require("firebase-functions/v2/auth");
const admin = require("firebase-admin");

// Limites globais (opcional)
setGlobalOptions({ maxInstances: 10 });

// Inicializar Admin SDK
admin.initializeApp();
const db = admin.firestore();

/**
 * Quando um utilizador é criado no Firebase Auth,
 * cria o documento correspondente em Firestore:
 *  - Coleção: usersAccounts
 *  - Doc ID: uid
 *  - Campos base: firstName, lastName, email, isActive, userProfile (ref), createdAt, lastLogin, photo, uid
 */
exports.provisionUserDoc = onUserCreated(async (event) => {

  const photoIconTemp = "https://www.google.com/url?sa=i&url=https%3A%2F%2Fwww.flaticon.com%2Ffree-icon%2Fuser_219983&psig=AOvVaw3bSsANlldNNpjU9WrSakUX&ust=1757697802618000&source=images&cd=vfe&opi=89978449&ved=0CBIQjRxqFwoTCLCeotyc0Y8DFQAAAAAdAAAAABAE"
  const user = event.data;
  const uid = user.uid;
  const email = user.email || "";
  //const photoURL = user.photoURL || null;
  const photoURL = user.photoURL || photoIconTemp;

  const docData = {
    uid,
    email,
    firstName: "",                 // podes preencher depois na app
    lastName: "",                  // idem
    isActive: false,               // começa inativo; ativa no backoffice/console
    userProfile: db.doc("usersProfiles/profileUser"), // referência ao perfil "utilizador"
    photo: photoURL,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastLogin: admin.firestore.FieldValue.serverTimestamp(),
  };

  await db.collection("usersAccounts").doc(uid).set(docData, { merge: true });
});

/**
 * (Opcional) Limpeza quando um utilizador é removido do Auth.
 * Apaga o doc correspondente em usersAccounts/{uid}.

 TODO: REVER se quero mesmo apagar ou nao!!
 */
exports.cleanupUserDoc = onUserDeleted(async (event) => {
  const uid = event.data.uid;
  await db.collection("usersAccounts").doc(uid).delete().catch(() => {});
});

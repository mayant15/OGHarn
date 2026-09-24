/* Generated with AI (Claude Code).
 *
 * X509_STORE_CTX_init stores raw pointers to the trust store and target
 * certificate without taking a reference, and X509_verify_cert dereferences
 * both, so freeing either while a ctx is bound is a use-after-free in the
 * harness, not in OpenSSL. These wrappers hold a reference on each for as long
 * as the ctx is bound, so the spec can hand the store and certificate back as
 * freeable after init.
 *
 * X509_STORE_CTX_cleanup leaves ctx->store and ctx->cert pointing at the old
 * objects, and X509_STORE_CTX_free calls cleanup, so unbinding re-initializes
 * the ctx with NULLs (which OpenSSL supports) before dropping the references.
 * That keeps "references held" equivalent to "ctx->store/ctx->cert non-NULL".
 *
 * NULL-ctx guards in x509_fuzz_ctx_unbind and x509_fuzz_ctx_init added with AI
 * assistance (Claude Code), after review: the get0 accessors dereference ctx,
 * so the wrappers crashed on a NULL ctx that X509_STORE_CTX_init rejects, and
 * init leaked the references it had just taken.
 */

#ifndef X509_SUPPORT_H
#define X509_SUPPORT_H

#include <openssl/x509.h>
#include <openssl/x509_vfy.h>

static void x509_fuzz_ctx_unbind(X509_STORE_CTX *ctx) {
  X509_STORE *store;
  X509 *cert;

  /* The get0 accessors dereference ctx without a NULL check. */
  if (ctx == NULL)
    return;
  store = X509_STORE_CTX_get0_store(ctx);
  cert = X509_STORE_CTX_get0_cert(ctx);
  if (store == NULL && cert == NULL)
    return;
  X509_STORE_CTX_init(ctx, NULL, NULL, NULL);
  X509_STORE_CTX_cleanup(ctx);
  X509_STORE_free(store);
  X509_free(cert);
}

int x509_fuzz_ctx_init(X509_STORE_CTX *ctx, X509_STORE *store, X509 *x509) {
  /* X509_STORE_CTX_init rejects a NULL ctx; do so before taking references,
     which would otherwise leak. */
  if (ctx == NULL)
    return X509_STORE_CTX_init(ctx, store, x509, NULL);
  x509_fuzz_ctx_unbind(ctx);
  if (store != NULL)
    X509_STORE_up_ref(store);
  if (x509 != NULL)
    X509_up_ref(x509);
  /* ctx->store/ctx->cert are set even if init fails, so the references stay
     held until the next unbind. */
  return X509_STORE_CTX_init(ctx, store, x509, NULL);
}

/* Like X509_STORE_CTX_cleanup at the pinned OpenSSL, this still dereferences
   a NULL ctx: only the wrapper's own accesses are guarded. */
void x509_fuzz_ctx_cleanup(X509_STORE_CTX *ctx) {
  x509_fuzz_ctx_unbind(ctx);
  X509_STORE_CTX_cleanup(ctx);
}

void x509_fuzz_ctx_free(X509_STORE_CTX *ctx) {
  if (ctx != NULL)
    x509_fuzz_ctx_unbind(ctx);
  X509_STORE_CTX_free(ctx);
}

#endif

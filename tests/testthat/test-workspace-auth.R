source(testthat::test_path("..", "..", "R", "workspace_auth.R"))

new_test_workspace_auth_provider <- function() {
  new_callback_workspace_auth_provider(
    current_user = function(session) {
      new_workspace_identity(
        authenticated = TRUE,
        subject = "example-provider|user-123",
        tenant_id = "deployment-a",
        display_name = "Example User"
      )
    },
    sign_in = function(session, ...) "https://identity.example.test/sign-in",
    sign_out = function(session, ...) invisible(TRUE),
    access_token = function(session, audience) {
      paste("token-for", if (is.null(audience)) "default" else audience, sep = ":")
    }
  )
}

testthat::test_that("anonymous authentication exposes no identity or token", {
  provider <- new_anonymous_workspace_auth_provider()
  identity <- workspace_auth_current_user(provider)

  testthat::expect_s3_class(provider, "workspace_auth_provider")
  testthat::expect_s3_class(identity, "workspace_identity")
  testthat::expect_false(identity$authenticated)
  testthat::expect_null(identity$subject)
  testthat::expect_null(workspace_auth_access_token(provider))
  testthat::expect_error(workspace_auth_sign_in(provider), "not configured", fixed = TRUE)
  testthat::expect_false(workspace_auth_sign_out(provider))
})

testthat::test_that("authenticated identities require opaque stable subjects", {
  testthat::expect_error(
    new_workspace_identity(authenticated = TRUE),
    "requires a stable subject",
    fixed = TRUE
  )
  testthat::expect_error(
    new_workspace_identity(subject = "user-123"),
    "cannot claim an authenticated subject",
    fixed = TRUE
  )

  identity <- new_workspace_identity(
    authenticated = TRUE,
    subject = "provider|user-123",
    tenant_id = "deployment-a",
    display_name = "Example User"
  )
  testthat::expect_silent(validate_workspace_identity(identity))
  testthat::expect_identical(identity$subject, "provider|user-123")
})

testthat::test_that("provider dispatch builds a validated access context", {
  provider <- new_test_workspace_auth_provider()
  context <- workspace_auth_context(provider, audience = "workspace-api")

  testthat::expect_true(context$identity$authenticated)
  testthat::expect_identical(context$identity$tenant_id, "deployment-a")
  testthat::expect_identical(context$access_token, "token-for:workspace-api")
  testthat::expect_identical(
    workspace_auth_sign_in(provider),
    "https://identity.example.test/sign-in"
  )
  testthat::expect_true(workspace_auth_sign_out(provider))
})

testthat::test_that("authentication providers are injectable per session", {
  old_options <- options(
    hetoolkit.workspace_auth_factory = function(session) new_test_workspace_auth_provider()
  )
  on.exit(options(old_options), add = TRUE)

  provider <- workspace_auth_provider_for_session(NULL)
  testthat::expect_s3_class(provider, "callback_workspace_auth_provider")
  testthat::expect_error(
    validate_workspace_auth_provider(function() NULL),
    "must implement the workspace auth interface",
    fixed = TRUE
  )
})

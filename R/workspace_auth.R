# Authentication providers expose a small, provider-neutral identity contract.
# Provider subjects are opaque stable identifiers; email addresses are display
# data and must not be used as workspace ownership keys.

new_workspace_identity <- function(
    authenticated = FALSE,
    subject = NULL,
    tenant_id = NULL,
    display_name = NULL) {
  if (!is.logical(authenticated) || length(authenticated) != 1L ||
      is.na(authenticated)) {
    stop("Workspace identity authentication status must be one logical value.", call. = FALSE)
  }

  validate_optional_identity_text <- function(value, field) {
    if (is.null(value)) {
      return(NULL)
    }
    if (!is.character(value) || length(value) != 1L || is.na(value) ||
        !nzchar(trimws(value))) {
      stop(sprintf("Workspace identity %s must be one non-empty text value.", field), call. = FALSE)
    }
    trimws(value)
  }

  subject <- validate_optional_identity_text(subject, "subject")
  tenant_id <- validate_optional_identity_text(tenant_id, "tenant ID")
  display_name <- validate_optional_identity_text(display_name, "display name")
  if (isTRUE(authenticated) && is.null(subject)) {
    stop("An authenticated workspace identity requires a stable subject.", call. = FALSE)
  }
  if (!isTRUE(authenticated) && !is.null(subject)) {
    stop("An anonymous workspace identity cannot claim an authenticated subject.", call. = FALSE)
  }

  structure(
    list(
      authenticated = authenticated,
      subject = subject,
      tenant_id = tenant_id,
      display_name = display_name
    ),
    class = "workspace_identity"
  )
}

validate_workspace_identity <- function(identity) {
  required_fields <- c("authenticated", "subject", "tenant_id", "display_name")
  if (!inherits(identity, "workspace_identity") || !is.list(identity) ||
      !all(required_fields %in% names(identity))) {
    stop("Workspace identity is invalid.", call. = FALSE)
  }
  new_workspace_identity(
    authenticated = identity$authenticated,
    subject = identity$subject,
    tenant_id = identity$tenant_id,
    display_name = identity$display_name
  )
  invisible(TRUE)
}

workspace_auth_current_user <- function(provider, session = NULL) {
  UseMethod("workspace_auth_current_user")
}

workspace_auth_sign_in <- function(provider, session = NULL, ...) {
  UseMethod("workspace_auth_sign_in")
}

workspace_auth_sign_out <- function(provider, session = NULL, ...) {
  UseMethod("workspace_auth_sign_out")
}

workspace_auth_access_token <- function(provider, session = NULL, audience = NULL) {
  UseMethod("workspace_auth_access_token")
}

validate_workspace_auth_provider <- function(provider) {
  if (!inherits(provider, "workspace_auth_provider")) {
    stop("Workspace authentication provider must implement the workspace auth interface.", call. = FALSE)
  }
  invisible(TRUE)
}

new_anonymous_workspace_auth_provider <- function() {
  structure(list(), class = c("anonymous_workspace_auth_provider", "workspace_auth_provider"))
}

new_callback_workspace_auth_provider <- function(
    current_user,
    sign_in,
    sign_out,
    access_token) {
  callbacks <- list(
    current_user = current_user,
    sign_in = sign_in,
    sign_out = sign_out,
    access_token = access_token
  )
  invalid_callbacks <- names(callbacks)[!vapply(callbacks, is.function, logical(1))]
  if (length(invalid_callbacks) > 0L) {
    stop(
      sprintf(
        "Workspace authentication callback(s) must be functions: %s.",
        paste(invalid_callbacks, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  structure(
    callbacks,
    class = c("callback_workspace_auth_provider", "workspace_auth_provider")
  )
}

workspace_auth_current_user.anonymous_workspace_auth_provider <- function(
    provider, session = NULL) {
  new_workspace_identity()
}

workspace_auth_sign_in.anonymous_workspace_auth_provider <- function(
    provider, session = NULL, ...) {
  stop("Workspace sign-in is not configured.", call. = FALSE)
}

workspace_auth_sign_out.anonymous_workspace_auth_provider <- function(
    provider, session = NULL, ...) {
  invisible(FALSE)
}

workspace_auth_access_token.anonymous_workspace_auth_provider <- function(
    provider, session = NULL, audience = NULL) {
  NULL
}

workspace_auth_current_user.callback_workspace_auth_provider <- function(
    provider, session = NULL) {
  identity <- provider$current_user(session)
  validate_workspace_identity(identity)
  identity
}

workspace_auth_sign_in.callback_workspace_auth_provider <- function(
    provider, session = NULL, ...) {
  provider$sign_in(session, ...)
}

workspace_auth_sign_out.callback_workspace_auth_provider <- function(
    provider, session = NULL, ...) {
  provider$sign_out(session, ...)
}

workspace_auth_access_token.callback_workspace_auth_provider <- function(
    provider, session = NULL, audience = NULL) {
  token <- provider$access_token(session, audience)
  if (!is.null(token) &&
      (!is.character(token) || length(token) != 1L || is.na(token) || !nzchar(token))) {
    stop("Workspace authentication provider returned an invalid access token.", call. = FALSE)
  }
  token
}

new_workspace_access_context <- function(identity = new_workspace_identity(), access_token = NULL) {
  validate_workspace_identity(identity)
  if (!is.null(access_token) &&
      (!is.character(access_token) || length(access_token) != 1L ||
       is.na(access_token) || !nzchar(access_token))) {
    stop("Workspace access token must be one non-empty text value.", call. = FALSE)
  }
  if (!isTRUE(identity$authenticated) && !is.null(access_token)) {
    stop("An anonymous workspace identity cannot have an access token.", call. = FALSE)
  }

  structure(
    list(identity = identity, access_token = access_token),
    class = "workspace_access_context"
  )
}

validate_workspace_access_context <- function(context) {
  if (!inherits(context, "workspace_access_context") || !is.list(context) ||
      !all(c("identity", "access_token") %in% names(context))) {
    stop("Workspace access context is invalid.", call. = FALSE)
  }
  new_workspace_access_context(context$identity, context$access_token)
  invisible(TRUE)
}

workspace_auth_context <- function(provider, session = NULL, audience = NULL) {
  validate_workspace_auth_provider(provider)
  identity <- workspace_auth_current_user(provider, session)
  validate_workspace_identity(identity)
  access_token <- if (isTRUE(identity$authenticated)) {
    workspace_auth_access_token(provider, session, audience)
  } else {
    NULL
  }
  new_workspace_access_context(identity, access_token)
}

workspace_auth_provider_for_session <- function(session = NULL) {
  factory <- getOption("hetoolkit.workspace_auth_factory", NULL)
  if (is.null(factory)) {
    return(new_anonymous_workspace_auth_provider())
  }
  if (!is.function(factory)) {
    stop("The configured workspace authentication factory must be a function.", call. = FALSE)
  }
  provider <- factory(session)
  validate_workspace_auth_provider(provider)
  provider
}

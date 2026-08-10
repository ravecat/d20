## 1. Endpoint Error Response Boundary

- [ ] 1.1 Add focused backend tests for production-like Inertia `403`, `404`, `500`, and `503` responses that assert the original status, `X-Inertia` header, error component, safe props, request version, request URL policy, and correlation identifier.
- [ ] 1.2 Add regression cases proving valid Inertia responses, redirects, unsupported statuses, non-Inertia requests, and development diagnostics are not normalized by the production boundary.
- [ ] 1.3 Implement the minimal endpoint `before_send` normalizer after `Plug.RequestId`, including environment gating, supported-status selection, safe same-origin URL derivation, request-version reuse, and removal of stale body headers.
- [ ] 1.4 Update focused page-controller and endpoint expectations so explicit forbidden and not-found Inertia branches use the central error page while conventional HTML requests retain their current status semantics.

## 2. Degraded Inertia Error Page

- [ ] 2.1 Add frontend unit and browser tests for status-specific copy, safe recovery navigation, optional request reference, document title, focus placement, visible keyboard focus, absence of private details, and supported narrow-viewport geometry.
- [ ] 2.2 Add the typed `error` page slice with fixed public mappings for `403`, `404`, `500`, and `503`, a normal safe navigation action, and no automatic retry of failed mutations.
- [ ] 2.3 Make the error page self-contained and exclude it from the authenticated application and workspace layout while preserving existing layout selection for every other Inertia page.
- [ ] 2.4 Verify the error page does not require shared authentication, session, workspace, exception, or submitted-request props.

## 3. Validation and Delivery

- [ ] 3.1 Format the touched Elixir files and run the focused plug, endpoint, controller, ErrorHTML, and frontend error-page tests.
- [ ] 3.2 Run `mix assets.lint`, `mix assets.test`, `mix typecheck`, and `mix assets.build` for the changed frontend boundary.
- [ ] 3.3 Run `openspec validate render-production-inertia-error-pages --strict --no-interactive` and the repository-wide `just check`, recording unrelated failures separately.
- [ ] 3.4 In a production-like environment, smoke-test representative `403`, `404`, `500`, and `503` Inertia visits, confirm no diagnostic dialog appears, and match a displayed `500` or `503` reference to the server request log.
- [ ] 3.5 Archive the completed OpenSpec change only after implementation and all required automated and production-like validation pass.

## Notes for Future Work

- Track which nixpkgs version currently pins Terraform and Stripe for reproducible installs.
- Document any manual steps required after `nix profile install` (e.g., shell hash refresh) so new devs can onboard quickly.
- Keep an updated list of CLI versions managed by this flake to avoid surprises when `nix flake update` bumps packages.

# Change log

## [0.0.12](https://github.com/weaselp/puppet-nft/tree/v0.0.12) (2025-10-29)

[Full Changelog](https://github.com/weaselp/puppet-nft/compare/v0.0.11...v0.0.12)

** Minor changes **

- Better support for nft in Debian 13: Do not use set-syntax for objects with
  only one entry.

## [0.0.11](https://github.com/weaselp/puppet-nft/tree/v0.0.11) (2025-07-09)

[Full Changelog](https://github.com/weaselp/puppet-nft/compare/v0.0.10...v0.0.11)

** Minor changes **

- Declare compatibility with puppet 8, new RedHats and Debians.
- Make pdk validate happy.
- Stricter nft:af\_filter\_address\_set\_object: complain if we get passed
  non-address objects.

## [0.0.10](https://github.com/weaselp/puppet-nft/tree/v0.0.10) (2024-07-01)

[Full Changelog](https://github.com/weaselp/puppet-nft/compare/v0.0.9...v0.0.10)

** Significant Changes **

- nft::simple changes the matching logic for empty saddr/daddr lists:
  If the list is defined (i.e. not undef) but empty, no rule is
  generated (the logic is that the empty set is never matched).  This is
  in particular true for mixed v4/v6 lists.  If, after filtering, either
  saddr or daddr is empty for one of the two address families, no rule
  is generated for that family.
  .
  For saddr\_not and daddr\_not, an empty list will still cause a rule
  to be created (with no filter on saddr/daddr).

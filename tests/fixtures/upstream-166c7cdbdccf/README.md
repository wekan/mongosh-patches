# Upstream patch URL regression fixtures

These two patch files are copied unchanged from mongodb-js/mongosh commit
`166c7cdbdccf1a641a7a5f25ae913a098f7702cf`, the source in the failed build.
Their added GitHub URLs are comments referencing a Node issue and Linux header,
not network requests. The upstream risk baseline records their exact contents.
Tests must still reject newly added URLs and telemetry calls.

Source: https://github.com/mongodb-js/mongosh/tree/166c7cdbdccf1a641a7a5f25ae913a098f7702cf/scripts/nodejs-patches

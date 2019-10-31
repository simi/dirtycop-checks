# Dirtycop checks

## env requirements

* DIRTYCOP_INSTALLATION_ID=123456789
* DIRTYCOP_APP_ID=123456789
* DIRTYCOP_APP_KEY=...
* GIT_COMMIT=912bfdbe5f19ecb045fc8798de8fa8a13ff17451
* REPO=simi/dirtycop-checks-test


## run checks
1. `dirtycop --against master --format json > result.json`
2. `bundle install`
3. `DIRTYCOP_INSTALLATION_ID=529162 DIRTYCOP_APP_ID=13821 DIRTYCOP_APP_KEY GIT_COMMIT=912bfdbe5f19ecb045fc8798de8fa8a13ff17451 REPO=simi/dirtycop-checks-test bundle exec ruby report-checks.rbbundle exec ruby report-checks.rb`


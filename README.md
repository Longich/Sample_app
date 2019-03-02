# Rails Tutorial

- 詰まったところ
  - bundle installを行ったときに失敗、
    - bundle updateを行えば解決（Gemfile.lockに書き込まれているからGemfileを変更したときに差分が生じるため
    - routes.rbがどうこうって言われるときはrootの場合だけ、hoge#indexとかのように#にする必要がある
  - herokuにpushするときにBundlerを上げろとのエラー
    - heroku buildpacks:set https://github.com/bundler/heroku-buildpack-bundler2
  - bcryptのhas_secure_passwordを利用していることで/users/1にアクセスした場合にエラー（rails test等はできた)
    - bcryptをgemに加えてからサーバー再起動をしていなかった
  
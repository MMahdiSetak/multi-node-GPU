export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$(go env GOPATH)/bin

go install -a github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest
go install -a github.com/brancz/gojsontoyaml@latest
go install -a github.com/google/go-jsonnet/cmd/jsonnet@latest

jb update

./build.sh example.jsonnet
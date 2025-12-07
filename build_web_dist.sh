set -ex
./build.sh release
rm -r Web/dist || true
npx vite build Web --base=./
mkdir Web/dist/assets/wasm
cp Web/wasm/App.wasm Web/dist/assets/wasm/
mkdir Web/dist/resources
cp -r Web/resources/* Web/dist/resources/

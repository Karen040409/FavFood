# Deploy favfood Flutter web app to Vercel (pre-built locally)
flutter build web --release --no-wasm-dry-run
Copy-Item -Force vercel.rewrites.json build/web/vercel.json
Push-Location build/web
vercel --prod
Pop-Location

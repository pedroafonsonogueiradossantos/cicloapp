# Ciclo App

Um aplicativo simples para pequenos negócios de serviços recorrentes.
App Flutter (focado no android, por enquanto), com login Google e dados
persistidos no Firestore.

## Stack

- **Flutter** (Material 3) + **Provider** para estado de UI
- **Firebase Auth** (Google Sign-In) + **Cloud Firestore** como backend atual
- **get_it** como service locator para injeção de dependência

## Arquitetura

```
lib/
  domain/repositories/   # contratos (PersonRepository, OrderRepository, AuthRepository, ...)
  data/firestore/        # implementação atual desses contratos, usando Firestore/Firebase Auth
  services/              # regra de negócio por entidade, dependendo só das interfaces acima
  providers/             # estado de UI (ex.: AuthProvider), também depende só de interfaces
  di/                    # service_locator.dart — único lugar que liga interface -> implementação
  screens/, widgets/     # UI, resolve Services via o service locator
  models/                # entidades de domínio (Person, Order, Address, ...)
```

Regra prática: **nada fora de `lib/data/firestore/` e `lib/di/` importa
`cloud_firestore` ou `firebase_auth`.** Trocar de backend (por exemplo para
uma API REST, SQLite ou outro BaaS) significa escrever novas implementações
dessas interfaces em `lib/data/<novo-backend>/` e repadronizar o
`service_locator.dart` — sem tocar em `services/`, `providers/` ou
`screens/`.

Os testes em `test/` comprovam isso na prática: usam repositórios falsos em
memória (não Firestore) injetados nos `Service`s.

## Como rodar

1. Crie um projeto no [Firebase Console](https://console.firebase.google.com/)
   com **Firestore** e **Authentication (Google)** habilitados.
2. Gere a configuração local do Firebase:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Isso cria `lib/firebase_options.dart`, `android/app/google-services.json`
   e `firebase.json` (todos gitignored, pois identificam o projeto Firebase
   específico — veja `lib/firebase_options.sample.dart` e
   `android/app/google-services.json.example` como referência de formato).
3. Instale as dependências e rode:
   ```bash
   flutter pub get
   flutter run
   ```

## Testes

```bash
flutter analyze
flutter test
```

## Licença

MIT — veja [LICENSE](LICENSE).

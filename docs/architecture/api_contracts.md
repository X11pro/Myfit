# API interna de referencia

## Auth

- `POST /auth/signup`
- `POST /auth/login`
- `POST /auth/logout`

## Profile

- `GET /profile`
- `PUT /profile`

## Food

- `POST /food/parse-text`
- `POST /food/analyze-photo`
- `GET /food/search`
- `POST /meals`
- `GET /meals?date=`
- `DELETE /meals/{id}`

## Workout

- `POST /workouts/manual`
- `GET /workouts?date=`
- `POST /health/import`
- `POST /strava/connect`
- `POST /strava/sync`

## Summary y coach

- `GET /daily-summary?date=`
- `GET /weekly-summary`
- `POST /coach/daily`
- `POST /coach/weekly`
- `POST /coach/supplements`

## Criterios

- Mantener respuestas JSON estructuradas.
- Devolver `confidence` cuando haya inferencia.
- Requerir confirmacion de usuario antes de persistir estimaciones dudosas.

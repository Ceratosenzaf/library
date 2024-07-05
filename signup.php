<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>MyBiblioteca</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous" />
  <link rel="stylesheet" href="index.css" />
</head>

<body class="center">
  <h1>
    Inserisci gli ultimi campi per poter registrarti
  </h1>

  <form method="post" action="signup-result.php" class="d-flex flex-column gap-4">
    <div class="form-group">
      <label for="nome">Nome</label>
      <input type="text" id="nome" name="nome" class="form-control text-center" placeholder="il tuo nome" required />
    </div>
    <div class="form-group">
      <label for="cognome">Cognome</label>
      <input type="password" id="cognome" name="cognome" class="form-control text-center" placeholder="il tuo cognome" required />
    </div>

    <button type="submit" class="btn btn-primary">
      Registrati
    </button>
  </form>
</body>

</html>
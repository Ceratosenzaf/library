<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Biblioteca</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous" />
  <link rel="stylesheet" href="index.css">
</head>

<body class="center">
  <?php

  session_start();
  $error = $_SESSION['error'] ?? null;
  unset($_SESSION['error']);

  if ($error == 'credentials')
    print("<h1>Credenziali errate</h1>");
  else if ($error == 'input')
    print("<h1>L'input non rispetta il formato richiesto</h1>");
  else if ($error === 'blocked')
    print("<h1>Sei stato bloccato</h1>");
  else if ($error === 'confirmPassword')
    print("<h1>Password e conferma password non coincidono</h1>");
  else
    print("<h1>Errore generico</h1>");

  ?>
  <a href="./">ritorna alla home</a>
</body>

</html>
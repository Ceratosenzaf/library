<?php
session_start();
session_unset();
?>


<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>MyBiblioteca</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous" />
  <link rel="stylesheet" href="index.css">
</head>

<body class="center">
  <h1>Sei un</h1>
  <div class="row">
    <a href="login.php?redirect=app" class="col btn btn-primary mx-4">
      <h5>Lettore</h5>
    </a>
    <a href="login.php?redirect=admin" class="col btn btn-primary mx-4">
      <h5>Bibliotecario</h5>
    </a>
  </div>
</body>

</html>
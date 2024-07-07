<?php
include('../utils/check-route.php');
check_user(true);
check_area('admin');
?>

<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Portale bibliotecari - MyBiblioteca</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous" />
  <link rel="stylesheet" href="../index.css" />
</head>

<body>
  <div>
    <?php include('../components/navbar.php') ?>

    <div class="center d-flex flex-column gap-4">
      <h1 style="margin-top: -56px;">Crea un nuovo utente lettore</h1>
      <form method="post" action="signup-result.php" class="d-flex flex-column gap-2">
        <input type="text" id="nome" name="nome" class="form-control text-center" placeholder="il suo nome" required />
        <input type="password" id="cognome" name="cognome" class="form-control text-center" placeholder="il suo cognome" required />
        <input type="text" id="cf" name="cf" class="form-control text-center" placeholder="il suo cf" required />
        <input type="password" id="password" name="password" class="form-control text-center" placeholder="la sua password" required />
        <button type="submit" class="btn btn-primary">Crea</button>
      </form>
    </div>
  </div>
</body>

</html>
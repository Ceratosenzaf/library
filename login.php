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
    <?php
    session_start();

    $_SESSION['area'] = $_GET['redirect'] ?? 'app';

    $area = $_SESSION['area'] == 'admin' ? 'bibliotecari' : 'lettori';
    print("Accedi all'area $area");
    ?>
  </h1>

  <form method="post" action="login-result.php" class="d-flex flex-column gap-4">
    <div class="form-group">
      <label for="cf">Codice Fiscale</label>
      <input type="text" id="cf" name="cf" class="form-control text-center" placeholder="il tuo cf" required />
    </div>
    <div class="form-group">
      <label for="password">Password</label>
      <input type="password" id="password" name="password" class="form-control text-center" placeholder="la tua password" required />
    </div>

    <button type="submit" class="btn btn-primary">
      Accedi
    </button>
  </form>
</body>

</html>
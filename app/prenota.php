<?php
include('../utils/check-route.php');
check_user(true);
check_area('app');

include('../utils/db.php');

if (!isset($_SESSION['isbn'])) redirect('./');

function prenota()
{
  $isbn = $_SESSION['isbn'];
  unset($_SESSION['isbn']);

  //TODO: implement

  return 'sede';
}
?>

<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Portale lettori - MyBiblioteca</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous" />
  <link rel="stylesheet" href="../index.css">
</head>

<body>
  <?php include('../components/navbar.php') ?>

  <?php
  $sede = prenota();
  if (!$sede) print '<h1>Errore in fase di prenotazione, ritenta</h1>';
  else {
    print "<h1>Prenotazione effettuata presso la sede di $sede</h1>";
  }
  ?>
</body>

</html>
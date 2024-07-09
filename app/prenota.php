<?php
include('../utils/check-route.php');
check_user(true);
check_area('app');

include('../utils/db.php');

function prenota()
{
  $isbn = $_SESSION['isbn'] ?? '';
  $cf = $_SESSION['user'] ?? '';
  $sede = $_POST['sede'] ?? null;

  if ($isbn == '' || $cf == '') return;
  unset($_SESSION['isbn']);


  $sql = "SELECT id_nuova_sede sede FROM check_and_insert_prestito(cf := $1, isbn := $2, id_sede := $3)";

  $db = open_pg_connection();
  $res = pg_prepare($db, 'new-lend', $sql);
  $res = pg_execute($db, 'new-lend', array($cf, $isbn, value_or_null($sede)));

  if (!$res) return;

  $row = pg_fetch_assoc($res);
  if (!$row) return;


  $sql = "
  SELECT s.id, s.indirizzo, c.nome FROM sede s 
  JOIN citta c ON c.id = s.citta 
  WHERE s.id = $1
  LIMIT 1
  ";

  $res = pg_prepare($db, 'new-lend-site', $sql);
  $res = pg_execute($db, 'new-lend-site', array($row['sede']));
  if (!$res) return;

  $row = pg_fetch_assoc($res);
  if (!$row) return;

  return $row;
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

  <div class="center d-flex flex-column gap-4">
    <?php
    include('../utils/nome.php');

    $sede = prenota();

    if (!$sede) print '<h1 style="margin-top: -56px">Errore in fase di prenotazione, ritenta</h1>';
    else {
      $nomeSede = get_site_name($sede['nome'], $sede['indirizzo']);
      print "<h1 style=\"margin-top: -56px\">Prenotazione effettuata presso la sede di <br> $nomeSede</h1>";
      print '<a href="./prestiti.php">Dettagli</a>';
    }
    ?>
  </div>
</body>

</html>
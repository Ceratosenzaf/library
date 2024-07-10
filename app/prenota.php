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

  $db = open_pg_connection();
  start_pg_transaction($db);

  function rollback_and_return($db)
  {
    $_SESSION['errorMessage'] = get_pg_parsed_error($db);
    rollback_pg_transaction($db);
    return;
  }

  // insert
  $sql = "SELECT id_prestito, id_sede FROM check_and_insert_prestito($1, $2, $3)";
  $res = pg_prepare($db, 'new-lend', $sql);
  $res = @pg_execute($db, 'new-lend', array($cf, $isbn, value_or_null($sede)));

  if (!$res) return rollback_and_return($db);

  $row = pg_fetch_assoc($res);
  if (!$row) return rollback_and_return($db);

  $prestito = $row['id_prestito'];

  // fetch new data
  $sql = "SELECT * FROM prestito WHERE id = $1";

  $res = pg_prepare($db, "select-post", $sql);
  $res = pg_execute($db, "select-post", array($prestito));

  if (!$res) return rollback_and_return($db);

  $dati_post = pg_fetch_assoc($res);

  if (!$dati_post) return rollback_and_return($db);

  $sql = "
  INSERT INTO log (tipo, prestito, dati_pre, dati_post)
  VALUES ('prestito', $1, $2, $3)
  ";

  $res = pg_prepare($db, "log-prestito", $sql);
  $res = pg_execute($db, "log-prestito", array($prestito, json_encode(new stdClass()), json_encode($dati_post)));

  if (!$res) return rollback_and_return($db);

  // notify
  $sql = "
  SELECT s.id, s.indirizzo, c.nome FROM sede s 
  JOIN citta c ON c.id = s.citta 
  WHERE s.id = $1
  LIMIT 1
  ";

  $res = pg_prepare($db, 'new-lend-site', $sql);
  $res = pg_execute($db, 'new-lend-site', array($row['id_sede']));
  if (!$res) return rollback_and_return($db);

  $row = pg_fetch_assoc($res);
  if (!$row) return rollback_and_return($db);

  commit_pg_transaction($db);
  return array($row, $prestito);
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

    $data = prenota();

    if (!$data) {
      print '<h1 style="margin-top: -56px">Errore in fase di prenotazione, ritenta</h1>';
      if ($_SESSION['errorMessage']) print $_SESSION['errorMessage'];
      unset($_SESSION['errorMessage']);
    } else {
      [$sede, $prestito] = $data;
      $nomeSede = get_site_name($sede['nome'], $sede['indirizzo']);
      print "<h1 style=\"margin-top: -56px\">Prenotazione effettuata presso la sede di <br> $nomeSede</h1>";
      print '<a href="./prestito.php?id=' . $prestito . '">Dettagli</a>';
    }
    ?>
  </div>
</body>

</html>
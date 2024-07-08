<?php
include('../utils/check-route.php');
check_user(true);
check_area('admin');

include('../utils/db.php');
include('../components/gallery.php');

function count_total_lends()
{
  $sql = "SELECT COUNT(*) tot FROM libro l";

  $db = open_pg_connection();
  $res = pg_prepare($db, 'lends-count', $sql);
  $res = pg_execute($db, 'lends-count', array());

  if (!$res) return 0;
  return pg_fetch_result($res, 0, 'tot') ?? 0;
}

function get_lends($pagination)
{
  $page = ($_GET['page'] ?? 1) - 1;
  $copia = $_GET['copia'] ?? null;
  $cf = $_GET['lettore'] ?? null;

  $sql = "
  SELECT p.id, p.inizio, p.scadenza, p.riconsegna FROM prestito p
  WHERE 
    ($3::varchar IS NULL OR p.lettore = $3::varchar) AND
    ($4::integer IS NULL OR p.copia = $4::integer)
  ORDER BY p.inizio DESC, p.riconsegna DESC
  LIMIT $1
  OFFSET $2
  ";

  $query_name = "copie-$page";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($pagination, $pagination * $page, $cf, $copia));

  if (!$res) return;

  $data = array();

  while ($row = pg_fetch_assoc($res))
    array_push($data, $row);

  return get_gallery($data, function($row) {
    return get_lend_card($row['id'], $row['inizio'], $row['scadenza'], $row['riconsegna']);
  });
}
?>

<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Portale bibliotecari - MyBiblioteca</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous" />
  <link rel="stylesheet" href="../index.css">
</head>

<body>
  <?php include('../components/navbar.php') ?>

  <div>
    <h1>Prestiti</h1>
  </div>

  <?php
  include('../components/pagination.php');

  get_lends(12);

  $tot = count_total_lends();
  get_pagination($tot, 12, $_GET['page'] ?? 1, $_GET['search'] ?? null);
  ?>
</body>

</html>
<?php
include('../utils/check-route.php');
check_user(true);
check_area('admin');

include('../utils/db.php');
include('../components/gallery.php');

function get_where() {
  $cf = $_GET['lettore'] ?? null;
  $copia = $_GET['copia'] ?? null;
  $sede = $_GET['sede'] ?? null;
  
  $join = "JOIN copia c ON c.id = p.copia";
  $where = "
  WHERE 
    ($1::varchar IS NULL OR p.lettore = $2::varchar) AND
    ($2::integer IS NULL OR p.copia = $2::integer) AND
    ($3::integer IS NULL OR c.sede = $3::integer)
  ";

  return array($join, $where, $cf, $copia, $sede);
}

function count_total_lends()
{
  [$join, $where, $cf, $copia, $sede] = get_where();

  $sql = "
  SELECT COUNT(*) tot FROM prestito p
  $join
  $where
  ";;

  $db = open_pg_connection();
  $res = pg_prepare($db, 'lends-count', $sql);
  $res = pg_execute($db, 'lends-count', array($cf, $copia, $sede));

  if (!$res) return 0;
  return pg_fetch_result($res, 0, 'tot') ?? 0;
}

function get_lends($pagination)
{
  [$join, $where, $cf, $copia, $sede] = get_where();
  $page = ($_GET['page'] ?? 1) - 1;

  $sql = "
  SELECT p.id, p.inizio, p.scadenza, p.riconsegna FROM prestito p
  $join
  $where
  ORDER BY p.riconsegna DESC, p.scadenza ASC
  LIMIT $4
  OFFSET $5
  ";

  $query_name = "copie-$page";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($cf, $copia, $sede, $pagination, $pagination * $page));

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
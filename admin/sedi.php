<?php
include('../utils/check-route.php');
check_user(true);
check_area('admin');

include('../utils/db.php');
include('../components/gallery.php');

function get_where() {
  $citta = $_GET['città'] ?? null;

  $join = "JOIN citta c ON c.id = s.citta";
  $where = "
  WHERE
  $1::integer IS NULL OR
  s.citta = $1::integer
  ";

  return array($join, $where, $citta);
}

function count_total_sites()
{
  [$join, $where, $citta] = get_where();

  $sql = "
  SELECT COUNT(*) tot FROM sede s
  $join
  $where
  ";

  $db = open_pg_connection();
  $res = pg_prepare($db, 'books-count', $sql);
  $res = pg_execute($db, 'books-count', array($citta));

  if (!$res) return 0;
  return pg_fetch_result($res, 0, 'tot') ?? 0;
}

function get_sites($pagination)
{
  [$join, $where, $citta] = get_where();
  $page = ($_GET['page'] ?? 1) - 1;

  $sql = "
  SELECT s.id, s.indirizzo, c.nome FROM sede s
  $join
  $where
  ORDER BY c.nome, s.indirizzo
  LIMIT $2
  OFFSET $3
  ";

  $query_name = "sites-$page";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($citta, $pagination, $pagination * $page));

  if (!$res) return;

  $data = array();

  while ($row = pg_fetch_assoc($res))
    array_push($data, $row);

  return get_gallery($data, function ($row) {
    return get_site_card($row['id'], $row['indirizzo'], $row['nome']);
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
    <h1>Sedi</h1>
    <a href="./sede.php">Nuova sede</a>
  </div>

  <?php
  include('../components/pagination.php');

  get_sites(12);

  $tot = count_total_sites();
  get_pagination($tot, 12, $_GET['page'] ?? 1, $_GET['search'] ?? null);
  ?>
</body>

</html>
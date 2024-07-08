<?php
include('../utils/check-route.php');
check_user(true);
check_area('admin');

include('../utils/db.php');
include('../components/gallery.php');

function count_total_copies()
{
  $sql = "SELECT COUNT(*) tot FROM libro l";

  $db = open_pg_connection();
  $res = pg_prepare($db, 'copies-count', $sql);
  $res = pg_execute($db, 'copies-count', array());

  if (!$res) return 0;
  return pg_fetch_result($res, 0, 'tot') ?? 0;
}

function get_copies($pagination)
{
  $search = $_GET['search'] ?? '';
  $page = ($_GET['page'] ?? 1) - 1;
  $libro = $_GET['isbn'] ?? null;
  $sede = $_GET['sede'] ?? null;

  $sql = "
  SELECT k.id, l.titolo, s.indirizzo, c.nome FROM copia k
  JOIN libro l ON l.isbn = k.libro 
  JOIN sede s ON s.id = k.sede 
  JOIN citta c ON c.id = s.citta 
  WHERE 
    (LOWER(l.titolo) LIKE LOWER($1) OR l.isbn LIKE $1) AND
    ($4::varchar IS NULL OR k.libro = $4::varchar) AND
    ($5::integer IS NULL OR k.sede = $5::integer)
  ORDER BY l.titolo, c.nome, s.indirizzo, k.id
  LIMIT $2
  OFFSET $3
  ";

  $query_name = "copie-$page-$search";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array("%$search%", $pagination, $pagination * $page, $libro, $sede));

  if (!$res) return;

  $data = array();

  while ($row = pg_fetch_assoc($res))
    array_push($data, $row);

  return get_gallery($data, function($row) {
    return get_copy_card($row['id'], $row['titolo'], $row['indirizzo'], $row['nome']);
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
    <h1>Copie</h1>
    <a href="./copia.php">Nuova copia</a>
  </div>

  <?php
  include('../components/pagination.php');

  get_copies(12);

  $tot = count_total_copies();
  get_pagination($tot, 12, $_GET['page'] ?? 1, $_GET['search'] ?? null);
  ?>
</body>

</html>
<?php
include('../utils/check-route.php');
check_user(true);
check_area('admin');

include('../utils/db.php');
include('../components/gallery.php');

function count_total_cities()
{
  $sql = "SELECT COUNT(*) tot FROM citta c";

  $db = open_pg_connection();
  $res = pg_prepare($db, 'books-count', $sql);
  $res = pg_execute($db, 'books-count', array());

  if (!$res) return 0;
  return pg_fetch_result($res, 0, 'tot') ?? 0;
}

function get_cities($pagination)
{
  $page = ($_GET['page'] ?? 1) - 1;

  $sql = "
  SELECT c.id, c.nome FROM citta c
  ORDER BY c.nome
  LIMIT $1
  OFFSET $2
  ";

  $query_name = "cities-$page";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($pagination, $pagination * $page));

  if (!$res) return;

  $data = array();

  while ($row = pg_fetch_assoc($res))
    array_push($data, $row);

  return get_gallery($data, function($row) {
    return get_city_card($row['id'], $row['nome']);
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
    <h1>Città</h1>
    <a href="./citta.php">Nuova città</a>
  </div>

  <?php
  include('../components/pagination.php');

  get_cities(12);

  $tot = count_total_cities();
  get_pagination($tot, 12, $_GET['page'] ?? 1, $_GET['search'] ?? null);
  ?>
</body>

</html>
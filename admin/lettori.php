<?php
include('../utils/check-route.php');
check_user(true);
check_area('admin');

include('../utils/db.php');
include('../components/gallery.php');

function count_total_users()
{
  $sql = "SELECT COUNT(*) tot FROM lettore l";

  $db = open_pg_connection();
  $res = pg_prepare($db, 'users-count', $sql);
  $res = pg_execute($db, 'users-count', array());

  if (!$res) return 0;
  return pg_fetch_result($res, 0, 'tot') ?? 0;
}

function get_users($pagination)
{
  $search = $_GET['search'] ?? '';
  $page = ($_GET['page'] ?? 1) - 1;

  $sql = "
  SELECT l.cf, l.nome, l.cognome FROM lettore l
  WHERE
    LOWER(l.cf) LIKE LOWER($1) OR
    LOWER(l.nome) LIKE LOWER($1) OR
    LOWER(l.cognome) LIKE LOWER($1)
  ORDER BY l.nome, l.cognome, l.cf
  LIMIT $2
  OFFSET $3
  ";

  $query_name = "utenti-$page-$search";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array("%$search%", $pagination, $pagination * $page));

  if (!$res) return;

  $data = array();

  while ($row = pg_fetch_assoc($res))
    array_push($data, $row);

  return get_gallery($data, function ($row) {
    return get_user_card($row['cf'], $row['nome'], $row['cognome']);
  });
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

  <div>
    <h1>Lettori</h1>
    <a href="./lettore.php">Nuovo lettore</a>
  </div>

  <?php
  include('../components/pagination.php');

  get_users(12);

  $tot = count_total_users();
  get_pagination($tot, 12, $_GET['page'] ?? 1, $_GET['search'] ?? null);
  ?>
</body>

</html>
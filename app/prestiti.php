<?php
include('../utils/check-route.php');
check_user(true);
check_area('app');

include('../utils/db.php');
include('../components/gallery.php');

function get_where()
{
  $cf = $_SESSION['user'];

  $join = "
  JOIN copia c ON c.id = p.copia
  JOIN libro l ON l.isbn = c.libro
  ";
  $where = "WHERE p.lettore = $1";

  return array($join, $where, $cf);
}

function count_total_lends()
{
  [$join, $where, $cf] = get_where();

  $sql = "
  SELECT COUNT(*) tot FROM prestito p
  $join
  $where
  ";

  $db = open_pg_connection();
  $res = pg_prepare($db, 'lends-count', $sql);
  $res = pg_execute($db, 'lends-count', array($cf));

  if (!$res) return 0;
  return pg_fetch_result($res, 0, 'tot') ?? 0;
}

function get_lends($pagination)
{
  [$join, $where, $cf] = get_where();
  $page = ($_GET['page'] ?? 1) - 1;

  $sql = "
  SELECT p.id, p.scadenza, p.riconsegna, l.titolo FROM prestito p
  $join
  $where
  ORDER BY p.riconsegna DESC, p.scadenza ASC
  LIMIT $2
  OFFSET $3
  ";

  $query_name = "prestiti-$page";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($cf, $pagination, $pagination * $page));

  if (!$res) return;

  $data = array();

  while ($row = pg_fetch_assoc($res))
    array_push($data, $row);

  return get_gallery($data, function ($row) {
    return get_app_lend_card($row['id'], $row['titolo'], $row['scadenza'], $row['riconsegna']);
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
    <h1>Prestiti</h1>
  </div>

  <?php
  include('../components/pagination.php');

  get_lends(12);

  $tot = count_total_lends();
  if(!$tot) print'<a href="./catalogo.php">Effettua ora il tuo primo prestito!</a>';
  get_pagination($tot, 12, $_GET['page'] ?? 1, null);
  ?>
</body>

</html>
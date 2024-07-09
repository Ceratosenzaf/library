<?php
include('../utils/check-route.php');
check_user(true);
check_area('admin');

include('../utils/db.php');
include('../components/gallery.php');

function get_where()
{
$sede = $_GET['sede'] ?? null;
$autore = $_GET['autore'] ?? null;
$editore = $_GET['editore'] ?? null;

$join = "
LEFT JOIN copia c ON c.libro = l.isbn
JOIN scrittura s ON s.libro = l.isbn
";
$where = "
WHERE
  ($1::integer IS NULL OR c.sede = $1::integer) AND
  ($2::integer IS NULL OR s.autore = $2::integer) AND
  ($3::integer IS NULL OR l.editore = $3::integer)
";
return array($join, $where, $sede, $autore, $editore);
}

function count_total_books()
{
  [$join, $where, $sede, $autore, $editore] = get_where();

  $sql = "
  SELECT COUNT(*) tot FROM libro l
  $join
  $where
  ";

  $db = open_pg_connection();
  $res = pg_prepare($db, 'books-count', $sql);
  $res = pg_execute($db, 'books-count', array($sede, $autore, $editore));

  if (!$res) return 0;
  return pg_fetch_result($res, 0, 'tot') ?? 0;
}

function get_books($pagination)
{
  [$join, $where, $sede, $autore, $editore] = get_where();
  $page = ($_GET['page'] ?? 1) - 1;

  $sql = "
  SELECT l.isbn, l.titolo, l.trama, l.editore, COUNT(c.id) tot FROM libro l
  $join
  $where
  GROUP BY l.isbn
  ORDER BY l.titolo, l.isbn
  LIMIT $4
  OFFSET $5
  ";

  $query_name = "catalogo-$page";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($sede, $autore, $editore, $pagination, $pagination * $page));

  if (!$res) return;

  $data = array();

  while ($row = pg_fetch_assoc($res))
    array_push($data, $row);

  return get_gallery($data, function($row) {
    return get_book_card($row['titolo'], $row['isbn'], $row['trama']);
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
    <h1>Libri</h1>
    <a href="./libro.php">Nuovo libro</a>
  </div>

  <?php
  include('../components/pagination.php');

  get_books(12);

  $tot = count_total_books();
  get_pagination($tot, 12, $_GET['page'] ?? 1, $_GET['search'] ?? null);
  ?>
</body>

</html>
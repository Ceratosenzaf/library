<?php
include('../utils/check-route.php');
check_user(true);
check_area('app');

include('../utils/db.php');
include('../components/gallery.php');

function get_where()
{
  $search = '%' . ($_GET['search'] ?? '') . '%';
  $autore =$_GET['autore'] ?? null;

  $join = "JOIN scrittura s ON s.libro = l.isbn";
  $where = "
  WHERE
    (LOWER(l.titolo) LIKE LOWER($1) OR l.isbn LIKE $1) AND
    ($2::integer IS NULL OR s.autore = $2::integer)
  ";

  return array($join, $where, $search, $autore);
}

function count_total_books()
{
  [$join, $where, $search, $autore] = get_where();

  $sql = "
  SELECT COUNT(*) tot FROM libro l 
  $join 
  $where
  ";

  $db = open_pg_connection();
  $res = pg_prepare($db, 'books-count', $sql);
  $res = pg_execute($db, 'books-count', array($search, $autore));

  if (!$res) return 0;
  return pg_fetch_result($res, 0, 'tot') ?? 0;
}

function get_books($pagination)
{
  [$join, $where, $search, $autore] = get_where();
  $page = ($_GET['page'] ?? 1) - 1;

  $sql = "
  SELECT l.isbn, l.titolo, l.trama, l.editore FROM libro l
  $join
  $where
  ORDER BY l.titolo, l.isbn
  LIMIT $3
  OFFSET $4
  ";

  $query_name = "catalogo-$page";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($search, $autore, $pagination, $pagination * $page));

  if (!$res) return;

  $data = array();

  while ($row = pg_fetch_assoc($res))
    array_push($data, $row);

  return get_gallery($data, function ($row) {
    return get_book_card($row['titolo'], $row['isbn'], $row['trama']);
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

  <h1>Catalogo</h1>

  <?php
  include('../components/pagination.php');

  get_books(12);

  $tot = count_total_books();
  get_pagination($tot, 12, $_GET['page'] ?? 1, $_GET['search'] ?? null);
  ?>
</body>

</html>
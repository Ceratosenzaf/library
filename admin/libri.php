<?php
include('../utils/check-route.php');
check_user(true);
check_area('admin');

include('../utils/db.php');
include('../components/gallery.php');

function count_total_books()
{
  $sql = "SELECT COUNT(*) tot FROM libro l";

  $db = open_pg_connection();
  $res = pg_prepare($db, 'books-count', $sql);
  $res = pg_execute($db, 'books-count', array());

  if (!$res) return 0;
  return pg_fetch_result($res, 0, 'tot') ?? 0;
}

function get_books($pagination)
{
  $search = $_GET['search'] ?? '';
  $page = ($_GET['page'] ?? 1) - 1;
  $sede = $_GET['sede'] ?? null;
  $autore = $_GET['autore'] ?? null;
  $editore = $_GET['editore'] ?? null;

  $sql = "
  SELECT l.isbn, l.titolo, l.trama, l.editore, COUNT(c.id) tot FROM libro l
  LEFT JOIN copia c ON c.libro = l.isbn
  JOIN scrittura s ON s.libro = l.isbn
  WHERE
    (LOWER(l.titolo) LIKE LOWER($1) OR l.isbn LIKE $1) AND
    ($4::integer IS NULL OR c.sede = $4::integer) AND
    ($5::integer IS NULL OR s.autore = $5::integer) AND
    ($6::integer IS NULL OR l.editore = $6::integer)
  GROUP BY l.isbn
  ORDER BY l.titolo, l.isbn
  LIMIT $2
  OFFSET $3
  ";

  $query_name = "catalogo-$page-$search";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array("%$search%", $pagination, $pagination * $page, $sede, $autore, $editore));

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
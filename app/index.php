<?php
include('../utils/check-route.php');
check_user(true);
check_area('app');

include('../utils/db.php');
include('../components/gallery.php');

function get_popular($days = -1, $limit = 3)
{

  $date = new DateTime();
  if ($days >= 0) $date->modify("-$days days");
  else $date->setTimestamp(0);

  $sql = "
  SELECT l.isbn, l.titolo, l.trama, l.editore, COUNT(*) tot FROM prestito p
  JOIN copia c ON p.copia = c.id
  JOIN libro l ON c.isbn = l.isbn
  WHERE p.inizio >= $1
  GROUP BY l.isbn
  ORDER BY tot
  LIMIT $2
  ";

  $query_name = "gallery-$days-$limit";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($date->format('Y-m-d'), $limit));

  if (!$res) return;

  $data = array();

  while ($row = pg_fetch_assoc($res)) 
    array_push($data, $row);

  return get_gallery($data);
}
?>

<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Portale lettori - MyBiblioteca</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous">
 <link rel="stylesheet" href="../index.css">
</head>

<body>
  <?php include('../components/navbar.php') ?>
  <h1>Portale lettori</h1>

  <h3>I più popolari del momento</h3>
  <?php get_popular(30); ?>

  <h3>I più popolari di sempre</h3>
  <?php get_popular(); ?>
</body>

</html>
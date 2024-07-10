<?php
include('../utils/check-route.php');
check_user(true);
check_area('app');

include('../utils/db.php');

$id = $_GET['id'] ?? null;
if (!$id) redirect('./catalogo.php');

function get_author()
{
  global $id;

  $sql = "
  SELECT * FROM autore a
  WHERE a.id = $1
  LIMIT 1
  ";

  $query_name = "author-$id";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($id));

  if (!$res) redirect('./catalogo.php');
  return pg_fetch_assoc($res);
}
?>

<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Portale lettori - MyBiblioteca</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous" />
  <link rel="stylesheet" href="../index.css" />
</head>

<body>
  <div>
    <?php include('../components/navbar.php') ?>

    <div class="center">

      <?php
      include('../components/card.php');

      $autore = get_author();

      print '<div>';
      print '<h1 style="margin-top: -56px;">' . get_writer_name($autore['pseudonimo'] ?? null, $autore['nome'] ?? null, $autore['cognome'] ?? null) . '</h1>';

      $b = $autore['nascita'] ?? 'sconosciuto';
      $d = $autore['morte'] ?? 'vivo';
      if (!empty($autore['nascita']) || !empty($autore['more'])) print "<h5>$b - $d</h5>";
      print '</div>';

      print '<p class="text-justify">' . $autore['biografia'] . '</p>';

      print '<a href="./catalogo.php?autore=' . $autore['id'] . '">Opere</a>';
      ?>
    </div>
  </div>
</body>

</html>
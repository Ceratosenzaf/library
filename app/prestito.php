<?php
include('../utils/check-route.php');
check_user(true);
check_area('app');

include('../utils/db.php');

$id = $_GET['id'] ?? null;
if (!$id) redirect('./prestiti.php');

function get_lend()
{
  global $id;

  $sql = "
  SELECT p.inizio, p.scadenza, p.riconsegna, c.libro, l.titolo FROM prestito p
  JOIN copia c ON c.id = p.copia
  JOIN libro l ON l.isbn = c.libro
  WHERE 
    p.id = $1 AND
    p.lettore = $2
  LIMIT 1
  ";

  $query_name = "lend-$id";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($id, $_SESSION['user']));

  if (!$res) redirect('./prestiti.php');
  return pg_fetch_assoc($res);
}
?>

<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Portale bibliotecari - MyBiblioteca</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-QWTKZyjpPEjISv5WaRU9OFeRpok6YctnYmDr5pNlyT2bRjXh0JMhjY6hW+ALEwIH" crossorigin="anonymous" />
  <link rel="stylesheet" href="../index.css" />
</head>

<body>
  <div>
    <?php include('../components/navbar.php') ?>

    <div class="center">
      <h1 style="margin-top: -56px">Dettagli prestito</h1>
      <div class="d-flex flex-column mx-auto max-w-content" style="text-align: left;">
        <?php
        include('../utils/nome.php');

        $prestito = get_lend();
        function get_v($k)
        {
          global $prestito;
          if (!$prestito) return;
          return $prestito[$k];
        }

        print '<h5 class="text-center mb-4"><span class="badge bg-primary">'.get_land_label(get_v('scadenza'), get_v('riconsegna')).'</span></h5>';
        print '<p><b>Libro: </b><a href="./libro.php?isbn=' . get_v('libro') . '">' . get_v('titolo') . '</a></p>';
        print '<p><b>Inizio: </b>' . get_v('inizio') . '</p>';
        if (get_v('riconsegna')) print '<p><b>Fine: </b>' . get_v('riconsegna') . '</p>';
        else print '<p><b>Scadenza: </b>' . get_v('scadenza') . '</p>';
        ?>

      </div>
    </div>
  </div>
</body>

</html>
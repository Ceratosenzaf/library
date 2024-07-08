<?php
include('../utils/check-route.php');
check_user(true);
check_area('admin');

include('../utils/db.php');

$id = $_GET['id'] ?? null;
if (!$id) redirect('./prestiti.php');
$_SESSION['prestito'] = $id;

function get_lend()
{
  $id = $_SESSION['prestito'];
  if (!$id) return;

  $sql = "
  SELECT * FROM prestito p
  WHERE p.id = $1
  LIMIT 1
  ";

  $query_name = "lend-$id";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($id));

  if (!$res) return;
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

    <div class="center d-flex flex-column gap-4">
      <h1 style="margin-top: -112px;">Dettagli prestito</h1>

      <div class="d-flex flex-column mx-auto max-w-content mb-4" style="text-align: left;">
        <?php
        include('../utils/nome.php');

        $prestito = get_lend();
        function get_v($k)
        {
          global $prestito;
          if (!$prestito) return;
          return $prestito[$k];
        }

        print '<p><b>Stato: </b>' . get_land_label(get_v('scadenza'), get_v('riconsegna')) . '</p>';
        print '<p><b>Copia: </b><a href="./copia.php?id=' . get_v('copia') . '">' . get_v('copia') . '</a></p>';
        print '<p><b>Lettore: </b><a href="./lettore.php?cf=' . get_v('lettore') . '">' . get_v('lettore') . '</a></p>';
        print '<p><b>Da: </b>' . get_v('inizio') . '</p>';
        if (get_v('riconsegna')) print '<p><b>A: </b>' . get_v('riconsegna') . '</p>';
        else print '<p><b>Scadenza: </b>' . get_v('scadenza') . '</p>';
        print '</div>';

        if (!get_v('riconsegna')) {
          $now = new DateTime();

          print '<h1>Gestisci prestito</h1>';

          // proroga
          print '<form method="post" action="proroga.php" class="d-flex gap-2 row">';
          print '<input type="date" id="data" name="data" class="col form-control text-center" placeholder="la sua nuova scadenza" required value="' . get_v('scadenza') . '" />';
          print '<button type="submit" class="col col-3 btn btn-primary">Proroga</button>';
          print '</form>';

          // riconsegna
          print '<form method="post" action="riconsegna.php" class="d-flex gap-2 row">';
          print '<input type="date" id="data" name="data" class="col form-control text-center" placeholder="la sua data di riconsegna" required value="' . $now->format('Y-m-d') . '" />';
          print '<button type="submit" class="col col-3 btn btn-primary">Riconsegna</button>';
          print '</form>';
        }
        ?>

      </div>
    </div>
</body>

</html>
<?php
include('../utils/check-route.php');
check_user(true);
check_area('admin');

include('../utils/db.php');

$id = $_GET['id'] ?? null;
$_SESSION['sede'] = $id;

function get_site()
{
  $id = $_SESSION['sede'];
  if (!$id) return;

  $sql = "
  SELECT s.id, s.indirizzo, s.citta FROM sede s
  WHERE s.id = $1
  LIMIT 1
  ";

  $query_name = "site-$id";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($id));

  if (!$res) return;
  return pg_fetch_assoc($res);
}

function get_all_cities()
{
  $sql = "
  SELECT c.id, c.nome FROM citta c
  ORDER BY c.nome
  ";

  $query_name = "cities";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array());

  if (!$res) return [];

  $data = array();

  while ($row = pg_fetch_assoc($res))
    array_push($data, $row);

  return $data;
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
      <h1 style="margin-top: -56px;">
        <?php print $_SESSION['sede'] ? 'Modifica sede' : 'Crea una nuova sede'; ?>
      </h1>
      <form method="post" action="<?php print $_SESSION['sede'] ? 'edit-site.php' : 'create-site.php'; ?>" class="d-flex flex-column gap-2 mb-4">
        <?php
        $sede = get_site();
        $cities = get_all_cities();
        function get_v($k)
        {
          global $sede;
          if (!$sede) return;
          return $sede[$k];
        }

        print '<input type="text" id="indirizzo" name="indirizzo" class="form-control text-center" placeholder="il suo indirizzo" required value="' . get_v('indirizzo') . '" />';
        print '<select name="città" title="città" class="form-control text-center d-block" required>';
        print '<option value="" disabled '.($_SESSION['sede'] ? '' : 'selected').'>città</option>';
        foreach ($cities as $city) {
          $selected = get_v('citta') == $city['id'] ? 'selected': '';
          print "<option $selected value=\"" . $city['id'] . '">' . $city['nome']. '</option>';
        }
        print '</select>';
        print '<button type="submit" class="btn btn-primary">' . ($_SESSION['sede'] ? 'Modifica' : 'Crea') . '</button>';
        ?>
      </form>

      <?php if ($_SESSION['sede']) print '<a href="./libri.php?sede=' . $_SESSION['sede'] . '">Catalogo</a>'; ?>
      <?php if ($_SESSION['libro']) print '<a href="./copie.php?sede=' . $_SESSION['sede'] . '">Copie</a>'; ?>
    </div>
  </div>
</body>

</html>
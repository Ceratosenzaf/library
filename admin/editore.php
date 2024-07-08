<?php
include('../utils/check-route.php');
check_user(true);
check_area('admin');

include('../utils/db.php');

$id = $_GET['id'] ?? null;
$_SESSION['editore'] = $id;

function get_publisher()
{
  $id = $_SESSION['editore'];
  if (!$id) return;

  $sql = "
  SELECT * FROM casa_editrice e
  WHERE e.id = $1
  LIMIT 1
  ";

  $query_name = "publisher-$id";

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
        <?php print $_SESSION['editore'] ? 'Modifica casa editrice' : 'Crea una nuova casa editrice'; ?>
      </h1>
      <form method="post" action="<?php print $_SESSION['editore'] ? 'edit-publisher.php' : 'create-publisher.php'; ?>" class="d-flex flex-column gap-2 mb-4">
        <?php
        $sede = get_publisher();
        $cities = get_all_cities();
        function get_v($k)
        {
          global $sede;
          if (!$sede) return;
          return $sede[$k];
        }

        print '<input type="text" id="nome" name="nome" class="form-control text-center" placeholder="il suo nome" required value="' . get_v('nome') . '" />';
        print '<input type="date" id="fondazione" name="fondazione" class="form-control text-center" placeholder="la sua data di fondazione" value="' . get_v('fondazione') . '" />';
        print '<input type="date" id="cessazione" name="cessazione" class="form-control text-center" placeholder="la sua data di cessazione" value="' . get_v('cessazione') . '" />';
        print '<select name="città" title="città" class="form-control text-center d-block my-2">';
        print '<option value="" disabled ' . ($_SESSION['editore'] ? '' : 'selected') . '>città</option>';
        foreach ($cities as $city) {
          $selected = get_v('citta') == $city['id'] ? 'selected' : '';
          print "<option $selected value=\"" . $city['id'] . '">' . $city['nome'] . '</option>';
        }
        print '</select>';
        print '<button type="submit" class="btn btn-primary">' . ($_SESSION['editore'] ? 'Modifica' : 'Crea') . '</button>';
        ?>
      </form>

      <?php if ($_SESSION['editore']) print '<a href="./libri.php?editore=' . $_SESSION['editore'] . '">Catalogo</a>'; ?>
    </div>
  </div>
</body>

</html>
<?php
include('../utils/check-route.php');
check_user(true);
check_area('admin');

include('../utils/db.php');

$id = $_GET['id'] ?? null;
$_SESSION['città'] = $id;

function get_city()
{
  $id = $_SESSION['città'];
  if (!$id) return;

  $sql = "
  SELECT c.id, c.nome FROM citta c
  WHERE c.id = $1
  LIMIT 1
  ";

  $query_name = "citta-$id";

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
      <h1 style="margin-top: -56px;">
        <?php print $_SESSION['città'] ? 'Modifica città' : 'Crea una nuova città'; ?>
      </h1>
      <form method="post" action="<?php print $_SESSION['città'] ? 'edit-city.php' : 'create-city.php'; ?>" class="d-flex flex-column gap-2 mb-4">
        <?php
        $citta = get_city();
        function get_v($k)
        {
          global $citta;
          if (!$citta) return;
          return $citta[$k];
        }

        print '<input type="text" id="nome" name="nome" class="form-control text-center" placeholder="il suo nome" required value="' . get_v('nome') . '" />';
        print '<button type="submit" class="btn btn-primary">' . ($_SESSION['città'] ? 'Modifica' : 'Crea') . '</button>';
        ?>
      </form>

      <?php if ($_SESSION['città']) print '<a href="./sedi.php?città=' . $_SESSION['città'] . '">Sedi</a>'; ?>
    </div>
  </div>
</body>

</html>
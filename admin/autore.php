<?php
include('../utils/check-route.php');
check_user(true);
check_area('admin');

include('../utils/db.php');

$id = $_GET['id'] ?? null;
$_SESSION['autore'] = $id;

function get_author()
{
  $id = $_SESSION['autore'];
  if (!$id) return;

  $sql = "
  SELECT * FROM autore a
  WHERE a.id = $1
  LIMIT 1
  ";

  $query_name = "autore-$id";

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
        <?php print $_SESSION['autore'] ? 'Modifica autore' : 'Crea un nuovo autore'; ?>
      </h1>
      <form method="post" action="<?php print $_SESSION['autore'] ? 'edit-author.php' : 'create-author.php'; ?>" class="d-flex flex-column gap-2 mb-4">
        <?php
        $lettore = get_author();
        function get_v($k)
        {
          global $lettore;
          if (!$lettore) return;
          return $lettore[$k];
        }

        print '<input type="text" id="nome" name="nome" class="form-control text-center" placeholder="il suo nome" value="' . get_v('nome') . '" />';
        print '<input type="text" id="cognome" name="cognome" class="form-control text-center" placeholder="il suo cognome" value="' . get_v('cognome') . '" />';
        print '<input type="text" id="pseudonimo" name="pseudonimo" class="form-control text-center" placeholder="il suo pseudonimo" value="' . get_v('pseudonimo') . '" />';
        print '<input type="date" id="nascita" name="nascita" class="form-control text-center" placeholder="la sua data di nascita" value="' . get_v('nascita') . '" />';
        print '<input type="date" id="morte" name="morte" class="form-control text-center" placeholder="la sua data di morte" value="' . get_v('morte') . '" />';
        print '<textarea id="biografia" name="biografia" class="form-control" rows="5" placeholder="breve biografia">' . get_v('biografia')  . '</textarea>';
        print '<button type="submit" class="btn btn-primary">' . ($_SESSION['autore'] ? 'Modifica' : 'Crea') . '</button>'
        ?>
      </form>

      <?php if ($_SESSION['autore']) print '<a href="./libri.php?autore=' . $_SESSION['autore'] . '">Opere</a>'; ?>
    </div>
  </div>
</body>

</html>
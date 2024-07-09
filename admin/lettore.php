<?php
include('../utils/check-route.php');
check_user(true);
check_area('admin');

include('../utils/db.php');

$cf = $_GET['cf'] ?? null;
$_SESSION['cf'] = $cf;

function get_user()
{
  $cf = $_SESSION['cf'];
  if (!$cf) return;

  $sql = "
  SELECT * FROM lettore l
  WHERE l.cf = $1
  LIMIT 1
  ";

  $query_name = "lettore-$cf";

  $db = open_pg_connection();
  $res = pg_prepare($db, $query_name, $sql);
  $res = pg_execute($db, $query_name, array($cf));

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
        <?php print $_SESSION['cf'] ? 'Modifica lettore' : 'Crea un nuovo lettore'; ?>
      </h1>
      <form method="post" action="<?php print $_SESSION['cf'] ? 'edit-user.php' : 'create-user.php'; ?>" class="d-flex flex-column gap-2 mb-4">
        <?php
        $lettore = get_user();
        function get_v($k)
        {
          global $lettore;
          if (!$lettore) return;
          return $lettore[$k];
        }

        print '<input type="text" id="cf" name="cf" class="form-control text-center" placeholder="il suo cf" required value="' . get_v('cf') . '"' . ($_SESSION['cf'] ? 'disabled' : '') . ' />';
        print '<input type="text" id="nome" name="nome" class="form-control text-center" placeholder="il suo nome" required value="' . get_v('nome') . '" />';
        print '<input type="text" id="cognome" name="cognome" class="form-control text-center" placeholder="il suo cognome" required value="' . get_v('cognome') . '" />';
        if (!$_SESSION['cf']) print '<input type="password" id="password" name="password" class="form-control text-center" placeholder="la sua password" required />';
        print '<input type="text" id="ritardi" name="ritardi" class="form-control text-center" placeholder="i suoi ritardi" disabled readonly value="' . (get_v('ritardi') ?? 0) . ' ritardi" />';
        print '
        <div class="form-check text-left max-w-content mx-auto">
          <input class="form-check-input" type="checkbox" value="true" name="premium" id="premium" ' . (get_v('premium') == 't' ? 'checked' : '') . ' />
          <label class="form-check-label" for="premium">
            Premium
          </label>
        </div>
        ';
        print '
        <div class="form-check text-left max-w-content mx-auto">
          <input class="form-check-input" type="checkbox" value="true" name="bloccato" id="bloccato" ' . (get_v('bloccato') == 't' ? 'checked' : '') . ' />
          <label class="form-check-label" for="bloccato">
            Bloccato
          </label>
        </div>
        ';
        print '<button type="submit" class="btn btn-primary">' . ($_SESSION['cf'] ? 'Modifica' : 'Crea') . '</button>'
        ?>
      </form>

      <div class="d-flex flex-column gap-1">
        <?php
        if (!$_SESSION['cf']) return;
        print '<a href="./reset-user-delays.php">Azzera ritardi</a>';
        print '<a href="./prestiti.php?lettore=' . $_SESSION['cf'] . '">Prestiti</a>';
        ?>
      </div>
    </div>
  </div>
</body>

</html>
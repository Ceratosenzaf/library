<div class="center d-flex flex-column gap-4">
  <h1 style="margin-top: -56px;">Modifica password</h1>
  <form action="../edit-password.php" method="post" class="d-flex flex-column gap-2 mb-4">
    <input class="form-control text-center" name="currentPassword" required placeholder="password corrente" type="password">
    <input class="form-control text-center" name="newPassword" required placeholder="nuova password" type="password">
    <input class="form-control text-center" name="confirmNewPassword" required placeholder="conferma nuova password" type="password">
    <button class="btn btn-primary" type="submit">Modifica</button>
  </form>
  
  <a href="../">Logout</a>
</div>
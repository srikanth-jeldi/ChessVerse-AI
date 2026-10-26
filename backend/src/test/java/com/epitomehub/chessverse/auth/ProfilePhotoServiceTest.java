package com.epitomehub.chessverse.auth;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import java.io.IOException;
import java.nio.file.*;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;
class ProfilePhotoServiceTest {
 @TempDir Path root;
 @Test void guestCanUploadAndFailedReplacementKeepsPreviousPhoto() throws Exception {
  var auth=mock(PlayerAuthenticationService.class);var repo=mock(PlayerAccountRepository.class);
  var player=new PlayerAccount("guest","Guest",null,"unused");player.guestAccount=true;
  when(auth.requireBearer("Bearer test")).thenReturn(new AuthenticatedPlayer(player.id,"guest","Guest",null));
  when(repo.findById(player.id)).thenReturn(Optional.of(player));
  var service=new ProfilePhotoService(auth,repo,root.toString(),"https://api.example.test");
  byte[] original={1,2,3};
  service.upload("Bearer test",new MockMultipartFile("file","profile.png","image/png",original));
  assertArrayEquals(original,Files.readAllBytes(root.resolve(player.id+".png")));
  MultipartFile failing=mock(MultipartFile.class);
  when(failing.getSize()).thenReturn(10L);when(failing.isEmpty()).thenReturn(false);
  when(failing.getContentType()).thenReturn("image/jpeg");
  when(failing.getInputStream()).thenThrow(new IOException("read failed"));
  assertThrows(AuthException.class,()->service.upload("Bearer test",failing));
  assertArrayEquals(original,Files.readAllBytes(root.resolve(player.id+".png")));
  assertFalse(Files.exists(root.resolve(player.id+".jpg")));
 }
}

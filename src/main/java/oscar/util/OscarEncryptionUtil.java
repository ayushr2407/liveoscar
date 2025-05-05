package oscar.util;

import java.util.Base64;
import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

public class OscarEncryptionUtil  {

    private static final String AES_TRANSFORMATION = "AES/CBC/PKCS5Padding";
    private static final String CHARSET = "UTF-8";

    // Replace this with a securely stored key (16 bytes for AES encryption)
    private static final String SECRET_KEY = "1234567890123456";

    /**
     * Encrypts the given plaintext using AES encryption with CBC mode and PKCS5 padding.
     *
     * @param plainText The plaintext to encrypt (e.g., "username:password:pin").
     * @return The encrypted string in the format "IV:ciphertext", where IV and ciphertext are Base64 encoded.
     * @throws Exception If encryption fails.
     */
    public static String encrypt(String plainText) throws Exception {
        // Generate a random IV (16 bytes for AES)
        byte[] iv = new byte[16];
        new java.security.SecureRandom().nextBytes(iv);
        IvParameterSpec ivSpec = new IvParameterSpec(iv);

        // Create AES key using the secret key
        SecretKeySpec keySpec = new SecretKeySpec(SECRET_KEY.getBytes(CHARSET), "AES");

        // Initialize Cipher for encryption
        Cipher cipher = Cipher.getInstance(AES_TRANSFORMATION);
        cipher.init(Cipher.ENCRYPT_MODE, keySpec, ivSpec);

        // Encrypt the plaintext
        byte[] cipherText = cipher.doFinal(plainText.getBytes(CHARSET));

        // Encode IV and ciphertext in Base64
        String ivBase64 = Base64.getEncoder().encodeToString(iv);
        String cipherTextBase64 = Base64.getEncoder().encodeToString(cipherText);

         // Combine IV and ciphertext for output
         String encryptedOutput = ivBase64 + ":" + cipherTextBase64;

         // Print the encrypted result to Tomcat logs
        //  System.out.println("Encrypted Output: " + encryptedOutput);
 
         // Return the encrypted result
         return encryptedOutput;
    }
}

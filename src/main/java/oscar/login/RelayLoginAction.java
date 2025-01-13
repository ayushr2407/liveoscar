package oscar.login;

import java.util.Base64;
import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.apache.struts.action.Action;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;
import org.apache.logging.log4j.Logger;
import org.oscarehr.util.MiscUtils;

public class RelayLoginAction extends Action {

    private static final Logger logger = MiscUtils.getLogger();

    // Replace this with a securely stored key (16-byte key for AES encryption)
    private static final String SECRET_KEY = "1234567890123456";
    private static final String AES_TRANSFORMATION = "AES/CBC/PKCS5Padding";

    @Override
    public ActionForward execute(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) {
        // System.out.println("RelayLoginAction invoked");


        try {
            // Step 1: Retrieve encrypted credentials from the request
            String encryptedCredentials = request.getParameter("credentials");
            if (encryptedCredentials == null || encryptedCredentials.isEmpty()) {
                throw new Exception("Missing encrypted credentials");
            }

            // Print encrypted credentials to Tomcat logs
            // System.out.println("Received Encrypted Credentials: " + encryptedCredentials);
            // logger.info("Encrypted credentials received: " + encryptedCredentials);

            // Step 2: Decrypt the credentials
            String decryptedCredentials = decrypt(encryptedCredentials, SECRET_KEY);

            // Print decrypted credentials to Tomcat logs
            // System.out.println("Decrypted Credentials: " + decryptedCredentials);
            // logger.info("Decrypted credentials: " + decryptedCredentials);

            String[] parts = decryptedCredentials.split(":");
            if (parts.length != 3) {
                throw new Exception("Invalid credentials format. Expected format: username:password:pin");
            }

            String username = parts[0];
            String password = parts[1];
            String pin = parts[2];

            // Print individual parts to logs
            // System.out.println("Username: " + username);
            // System.out.println("Password: " + password);
            // System.out.println("PIN: " + pin);

            // logger.info("Relay login attempt for user: " + username);

            // Step 3: Forward the decrypted credentials to the existing /login endpoint
            request.setAttribute("username", username);
            request.setAttribute("password", password);
            request.setAttribute("pin", pin);

            // Forward internally to /login
            return mapping.findForward("login");

        } catch (Exception e) {
            // Log error and print to Tomcat logs
            logger.error("Error in RelayLoginAction: ", e);
            System.out.println("Error in RelayLoginAction: " + e.getMessage());

            // Forward to error page in case of failure
            request.setAttribute("errorMessage", "Failed to process login: " + e.getMessage());
            return mapping.findForward("error");
        }
    }

    private String decrypt(String encryptedData, String secretKey) throws Exception {
        // Split the encrypted data into IV and ciphertext
        String[] parts = encryptedData.split(":");
        if (parts.length != 2) {
            throw new Exception("Invalid encrypted data format");
        }

        byte[] iv = Base64.getDecoder().decode(parts[0]);
        byte[] cipherText = Base64.getDecoder().decode(parts[1]);

        Cipher cipher = Cipher.getInstance(AES_TRANSFORMATION);
        SecretKeySpec keySpec = new SecretKeySpec(secretKey.getBytes("UTF-8"), "AES");
        IvParameterSpec ivSpec = new IvParameterSpec(iv);

        cipher.init(Cipher.DECRYPT_MODE, keySpec, ivSpec);
        byte[] decryptedBytes = cipher.doFinal(cipherText);

        return new String(decryptedBytes, "UTF-8");
    }
}

package oscar.oscarRx.util;

import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import org.json.JSONArray;
import org.json.JSONObject;
import org.oscarehr.common.model.PharmacyInfo;

import oscar.oscarRx.data.RxPharmacyData;

public class PharmacyAPIFetcher {
    public void fetchAndSavePharmacies() {
        try (CloseableHttpClient httpClient = HttpClients.createDefault()) {
            HttpGet request = new HttpGet("https://oatrx.ca/api/fetch-all-pharmacies");
            String jsonResponse = EntityUtils.toString(httpClient.execute(request).getEntity());
            
            JSONObject responseObject = new JSONObject(jsonResponse);
            JSONArray pharmacies = responseObject.getJSONArray("data");
            
            System.out.println("Number of pharmacies: " + pharmacies.length());

            RxPharmacyData rxPharmacyData = new RxPharmacyData();
            int totalPharmacies = 0;

            for (int i = 0; i < pharmacies.length(); i++) {
                JSONObject pharmacy = pharmacies.getJSONObject(i);
                int active = pharmacy.optInt("active", 1);  // Use 'active' instead of 'activation_status'
                Character status = (active == 1) ? PharmacyInfo.ACTIVE : PharmacyInfo.DELETED;

                  // Fetch latitude and longitude
                  double latitude = pharmacy.optDouble("lat", 0.0);
                  double longitude = pharmacy.optDouble("lng", 0.0);
                rxPharmacyData.addOrUpdatePharmacy(
                    pharmacy.getInt("id"),
                    pharmacy.getString("name"),
                    pharmacy.getString("address"),
                    pharmacy.getString("city"),
                    pharmacy.getString("province"),
                    pharmacy.optString("zip_code", ""),
                    pharmacy.optString("phone", ""),
                    "",  // phone2 (not provided in API)
                    pharmacy.optString("fax", ""),
                    pharmacy.optString("email", ""),
                    "",  // serviceLocationIdentifier (not provided in API)
                    "",  // notes (not provided in API)
                    status,
                    pharmacy.optDouble("lat", 0.0), // Pass latitude
                    pharmacy.optDouble("lng", 0.0)
                );
                totalPharmacies++;
            }

            System.out.println("Total pharmacies processed: " + totalPharmacies);

        } catch (Exception e) {
            System.err.println("Error fetching pharmacies: " + e.getMessage());
            e.printStackTrace();
        }
    }
}


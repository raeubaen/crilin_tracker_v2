
#include <TTree.h>
#include <TH1.h>
#include <TH1D.h>
#include <TF1.h>
#include <TROOT.h>
#include <TDirectory.h>
#include <TString.h>
#include <TFitResultPtr.h>

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <cmath>

void scan_dcb(TTree *tree,
              const char *csvPath = "on_lxplus/scan_positions.csv",
              const char *outPath = "dcb_scan_results.csv")
{
    if (!tree) {
        std::cerr << "Errore: tree nullo!" << std::endl;
        return;
    }

    std::ifstream in(csvPath);
    if (!in.is_open()) {
        std::cerr << "Impossibile aprire " << csvPath << std::endl;
        return;
    }

    std::ofstream out(outPath);
    if (!out.is_open()) {
        std::cerr << "Impossibile creare " << outPath << std::endl;
        return;
    }

    out << "run,x,y,"
        << "mean_y_d,mean_y_d_err,"
        << "mean_y_u,mean_y_u_err,"
        << "mean_x_d,mean_x_d_err,"
        << "mean_x_u,mean_x_u_err,"
        << "sigma_x,sigma_x_err,"
        << "sigma_y,sigma_y_err,"
        << "status\n";

    // Fit DCB e restituisce media, errore sulla media,
    // sigma ed errore sulla sigma.
    auto fitDCB = [&](const TString &expr,
                      const TString &hname,
                      const TString &cut,
                      double &mean,
                      double &meanErr,
                      double &sigma,
                      double &sigmaErr) -> bool
    {
        // Elimina eventuali istogrammi precedenti con lo stesso nome.
        gDirectory->Delete(hname + ";*");

        TString drawCmd = Form("%s>>%s(100,-5,5)",
                               expr.Data(), hname.Data());

        Long64_t nSelected = tree->Draw(drawCmd, cut, "goff");

        TH1 *h = (TH1*)gDirectory->Get(hname);
        if (!h || nSelected < 20 || h->GetEntries() < 20) {
            std::cerr << "Entries insufficienti per " << hname
                      << ": " << nSelected << std::endl;
            return false;
        }

        // Usa la funzione dcb(TH1*) definita in dcb.cxx.
        dcb(h);

        TF1 *f = h->GetFunction("dcb");
        if (!f) {
            std::cerr << "Fit non trovato per " << hname << std::endl;
            return false;
        }

        mean     = f->GetParameter(4);
        meanErr  = f->GetParError(4);
        sigma    = f->GetParameter(5);
        sigmaErr = f->GetParError(5);

        return std::isfinite(mean) &&
               std::isfinite(meanErr) &&
               std::isfinite(sigma) &&
               std::isfinite(sigmaErr);
    };

    std::string line;
    std::getline(in, line); // Salta header: x,y,run

    while (std::getline(in, line)) {
        if (line.empty()) continue;

        std::stringstream ss(line);
        std::string sx, sy, sr;

        if (!std::getline(ss, sx, ',')) continue;
        if (!std::getline(ss, sy, ',')) continue;
        if (!std::getline(ss, sr, ',')) continue;

        double x = std::stod(sx);
        double y = std::stod(sy);
        int run  = std::stoi(sr);

        TString cut = Form("run == %d", run);

        double muYD = NAN, errYD = NAN, sigYD = NAN, errSigYD = NAN;
        double muYU = NAN, errYU = NAN, sigYU = NAN, errSigYU = NAN;
        double muXD = NAN, errXD = NAN, sigXD = NAN, errSigXD = NAN;
        double muXU = NAN, errXU = NAN, sigXU = NAN, errSigXU = NAN;

        // 1. Media Y del sensore d rispetto a true_y
        bool okYD = fitDCB(
            "reco_y_d_corr-true_y",
            Form("h_y_d_%d", run), cut,
            muYD, errYD, sigYD, errSigYD
        );

        // 2. Media Y del sensore u rispetto a true_y
        bool okYU = fitDCB(
            "reco_y_u_corr-true_y",
            Form("h_y_u_%d", run), cut,
            muYU, errYU, sigYU, errSigYU
        );

        // 3. Media X del sensore d rispetto a true_x
        bool okXD = fitDCB(
            "reco_x_d_corr-true_x",
            Form("h_x_d_%d", run), cut,
            muXD, errXD, sigXD, errSigXD
        );

        // 4. Media X del sensore u rispetto a true_x
        bool okXU = fitDCB(
            "reco_x_u_corr-true_x",
            Form("h_x_u_%d", run), cut,
            muXU, errXU, sigXU, errSigXU
        );

        // 5. Sigma X dalla differenza tra i due sensori X
        double muDiffX = NAN, errMuDiffX = NAN;
        double sigmaX = NAN, sigmaErrX = NAN;

        bool okDiffX = fitDCB(
            "reco_x_d_corr-reco_x_u_corr",
            Form("h_delta_x_%d", run), cut,
            muDiffX, errMuDiffX, sigmaX, sigmaErrX
        );

        // 6. Sigma Y dalla differenza tra i due sensori Y
        double muDiffY = NAN, errMuDiffY = NAN;
        double sigmaY = NAN, sigmaErrY = NAN;

        bool okDiffY = fitDCB(
            "reco_y_d_corr-reco_y_u_corr",
            Form("h_delta_y_%d", run), cut,
            muDiffY, errMuDiffY, sigmaY, sigmaErrY
        );

        bool allOK = okYD && okYU && okXD && okXU &&
                     okDiffX && okDiffY;

        int status = allOK ? 0 : 1;

        out << run << "," << x << "," << y << ","
            << muYD << "," << errYD << ","
            << muYU << "," << errYU << ","
            << muXD << "," << errXD << ","
            << muXU << "," << errXU << ","
            << sigmaX << "," << sigmaErrX << ","
            << sigmaY << "," << sigmaErrY << ","
            << status << "\n";

        std::cout << "\nRun " << run
                  << " (x=" << x << ", y=" << y << ")\n";

        std::cout << "  mean Y d = " << muYD << " +/- " << errYD << "\n";
        std::cout << "  mean Y u = " << muYU << " +/- " << errYU << "\n";
        std::cout << "  mean X d = " << muXD << " +/- " << errXD << "\n";
        std::cout << "  mean X u = " << muXU << " +/- " << errXU << "\n";
        std::cout << "  sigma X  = " << sigmaX << " +/- " << sigmaErrX << "\n";
        std::cout << "  sigma Y  = " << sigmaY << " +/- " << sigmaErrY << "\n";
        std::cout << "  status   = " << status << "\n";
    }

    in.close();
    out.close();

    std::cout << "\nRisultati salvati in "
              << outPath << std::endl;
}

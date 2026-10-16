root $1 << EOF

  TGraph* HistToGraphSwapXY(const TH1* h) {
      if (!h) return nullptr;
      TGraph* g = new TGraph();
      int ip = 0;
      for (int ibin = 1; ibin <= h->GetNbinsX(); ++ibin)
      {
          double y = h->GetBinContent(ibin);
          if (y == 0.)
              continue;
          double x = h->GetBinCenter(ibin);
          // scambia X e Y
          g->SetPoint(ip++, y, x);
      }
      return g;
  }

  std::string TF1ToString(const TF1* f,
                          const std::string& xname = "x") {
      TString s = f->GetExpFormula("P"); // sostituisce [0],[1],... con i valori
      std::string expr = s.Data();
      // sostituisci x con il nome desiderato
      size_t pos = 0;
      while ((pos = expr.find("x", pos)) != std::string::npos)
      {
          expr.replace(pos, 1, xname);
          pos += xname.size();
      }
      return expr;
  }


  recoTree->Draw("reco_y_u:true_y>>h_y_u(60, -14.5, 14.5, 3000, -15, 15)", "abs(true_x) < 12 && abs(true_y) < 12", "zcol")

  h_y_u->FitSlicesY()
  h_y_u->SaveAs("h_y_u_$2.root")
  auto *g_y_u = HistToGraphSwapXY(h_y_u_1)

  g_y_u->Fit("pol5")
  auto *f = g_y_u->GetFunction("pol5")
  TString s(TF1ToString(f, "reco_y_u"))
  cout << s.Data() << endl;

  recoTree->SetAlias("reco_y_u_corr", s.Data());
  cout << "alias: " << Form("recoTree->SetAlias(\"reco_y_u_corr\", %s);", s.Data()) << endl;

  g_y_u->SetName("graph_calibrate_y_u_$2")
  g_y_u->SaveAs("graph_calibrate_y_u_$2.root")
  auto *c_y_u = new TCanvas("canvas_calibrate_y_u_$2")
  g_y_u->Draw("AP")
  c_y_u->SaveAs("canvas_calibrate_y_u_$2.root")



  recoTree->Draw("reco_x_u:true_x>>h_x_u(60, -14.5, 14.5, 3000, -15, 15)", "abs(true_x) < 12 && abs(true_y) < 12", "zcol")

  h_x_u->FitSlicesY()
  h_x_u->SaveAs("h_x_u_$2.root")
  auto *g_x_u = HistToGraphSwapXY(h_x_u_1)

  g_x_u->Fit("pol5")
  g_x_u->GetFunction("pol5")
  auto *f = g_x_u->GetFunction("pol5")
  auto s = TF1ToString(f, "reco_x_u")
  recoTree->SetAlias("reco_x_u_corr", s.c_str());
  cout << "alias: " << Form("recoTree->SetAlias(\"reco_x_u_corr\", %s);", s.c_str()) << endl;

  g_x_u->SetName("graph_calibrate_x_u_$2")
  g_x_u->SaveAs("graph_calibrate_x_u_$2.root")
  auto *c_x_u = new TCanvas("canvas_calibrate_x_u_$2")
  g_x_u->Draw("AP")
  c_x_u->SaveAs("canvas_calibrate_x_u_$2.root")



  recoTree->Draw("reco_y_d:true_y>>h_y_d(60, -14.5, 14.5, 3000, -15, 15)", "abs(true_x) < 12 && abs(true_y) < 12", "zcol")

  h_y_d->FitSlicesY()
  h_y_d->SaveAs("h_y_d_$2.root")
  auto *g_y_d = HistToGraphSwapXY(h_y_d_1)

  g_y_d->Fit("pol5")
  g_y_d->GetFunction("pol5")
  auto *f = g_y_d->GetFunction("pol5")
  auto s = TF1ToString(f, "reco_y_d")
  recoTree->SetAlias("reco_y_d_corr", s.c_str());
  cout << "alias: " << Form("recoTree->SetAlias(\"reco_y_d_corr\", %s);", s.c_str()) << endl;

  g_y_d->SetName("graph_calibrate_y_d_$2")
  g_y_d->SaveAs("graph_calibrate_y_d_$2.root")
  auto *c_y_d = new TCanvas("canvas_calibrate_y_d_$2")
  g_y_d->Draw("AP")
  c_y_d->SaveAs("canvas_calibrate_y_d_$2.root")



  recoTree->Draw("reco_x_d:true_x>>h_x_d(60, -14.5, 14.5, 3000, -15, 15)", "abs(true_x) < 12 && abs(true_y) < 12", "zcol")

  h_x_d->FitSlicesY()
  h_x_d->SaveAs("h_x_d_$2.root")
  auto *g_x_d = HistToGraphSwapXY(h_x_d_1)

  g_x_d->Fit("pol5")
  g_x_d->GetFunction("pol5")
  auto *f = g_x_d->GetFunction("pol5")
  auto s = TF1ToString(f, "reco_x_d")
  recoTree->SetAlias("reco_x_d_corr", s.c_str());
  cout << "alias: " << Form("recoTree->SetAlias(\"reco_x_d_corr\", %s);", s.c_str()) << endl;
  g_x_d->SetName("graph_calibrate_x_d_$2")
  g_x_d->SaveAs("graph_calibrate_x_d_$2.root")
  auto *c_x_d = new TCanvas("canvas_calibrate_x_d_$2")
  g_x_d->Draw("AP")
  c_x_d->SaveAs("canvas_calibrate_x_d_$2.root")


  recoTree->Draw("reco_x_d_corr - reco_x_u_corr:true_x>>h_delta_x(60, -14.5, 14.5, 3000, -15, 15)", "abs(true_x) < 12 && abs(true_y) < 12", "zcol")
  recoTree->Draw("reco_y_d_corr - reco_y_u_corr:true_x>>h_delta_y(60, -14.5, 14.5, 3000, -15, 15)", "abs(true_x) < 12 && abs(true_y) < 12", "zcol")
  h_delta_x->SaveAs("h_delta_x_$2.root")
  h_delta_y->SaveAs("h_delta_y_$2.root")

  recoTree->Draw("reco_x_d_corr - reco_x_u_corr>>h_delta_x_center_$2(3000, -15, 15)", "true_x == 0 && true_y == 0", "zcol")
  recoTree->Draw("reco_y_d_corr - reco_y_u_corr>>h_delta_y_center_$2(3000, -15, 15)", "true_x == 0 && true_y == 0", "zcol")
  h_delta_x_center_$2->SaveAs("h_delta_x_center_$2.root")
  h_delta_y_center_$2->SaveAs("h_delta_y_center_$2.root")


EOF

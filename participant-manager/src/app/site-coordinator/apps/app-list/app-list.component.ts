import {Component, OnInit} from '@angular/core';
import {BehaviorSubject, combineLatest, Observable} from 'rxjs';
import {map} from 'rxjs/operators';
import {of} from 'rxjs';
import {AppsService} from '../shared/apps.service';
import {ManageApps, App} from '../shared/app.model';
import {Permission} from 'src/app/shared/permission-enums';
import {SearchService} from 'src/app/shared/search.service';
import {ToastrService} from 'ngx-toastr';
import {SearchTermService} from 'src/app/service/search-term.service';
@Component({
  selector: 'app-app-list',
  templateUrl: './app-list.component.html',
})
export class AppListComponent implements OnInit {
  query$ = new BehaviorSubject('');
  manageApp$: Observable<ManageApps> = of();
  manageAppsBackup = {} as ManageApps;
  loadMoreEnabled = true;
  limit = 10;
  searchValue = '';
  appUsersMessageMapping: {[k: string]: string} = {
    '=0': 'No App Users',
    '=1': 'One App User',
    'other': '# App Users',
  };
  studiesMessageMapping: {[k: string]: string} = {
    '=0': 'No Studies',
    '=1': 'One Study',
    'other': '# Studies',
  };

  constructor(
    private readonly appService: AppsService,
    private readonly sharedService: SearchService,
    private readonly toastr: ToastrService,
    private readonly searchTerm: SearchTermService,
  ) {}

  ngOnInit(): void {
    this.searchTerm.searchParameter$.subscribe((upadtedUsername) => {
      this.manageAppsBackup = {} as ManageApps;
      this.searchValue = upadtedUsername;
      this.getApps();
    });
    this.sharedService.updateSearchPlaceHolder('Search by App ID or Name');
  }

  getApps(): void {
    this.manageApp$ = combineLatest(
      this.appService.getUserApps(this.limit, 0, this.searchValue),
      this.query$,
    ).pipe(
      map(([manageApps, query]) => {
        this.manageAppsBackup = {...manageApps};

        if (!manageApps.superAdmin && manageApps.studyPermissionCount < 2) {
          this.toastr.error(
            'This view displays app-wise enrollment if you manage multiple studies.',
          );
        }
        this.manageAppsBackup.apps = this.manageAppsBackup.apps.filter(
          (app: App) =>
            app.name?.toLowerCase().includes(query.toLowerCase()) ||
            app.customId?.toLowerCase().includes(query.toLowerCase()),
        );

        this.loadMoreEnabled =
          this.manageAppsBackup.apps.length % this.limit === 0 ? true : false;
        console.log(this.loadMoreEnabled);

        return this.manageAppsBackup;
      }),
    );
  }
  search(query: string): void {
    this.query$.next(query.trim());
  }
  progressBarColor(app: App): string {
    if (app.enrollmentPercentage && app.enrollmentPercentage > 70) {
      return 'green__text__sm';
    } else if (
      app.enrollmentPercentage &&
      app.enrollmentPercentage >= 30 &&
      app.enrollmentPercentage <= 70
    ) {
      return 'orange__text__sm';
    } else {
      return 'red__text__sm';
    }
  }
  checkEditPermission(permission: number): boolean {
    return permission === Permission.ViewAndEdit;
  }
  checkViewPermission(permission: number): boolean {
    return (
      permission === Permission.View || permission === Permission.ViewAndEdit
    );
  }

  loadMoreSites() {
    const offset = this.manageAppsBackup.apps.length;
    this.manageApp$ = combineLatest(
      this.appService.getUserApps(this.limit, offset, this.searchValue),
      this.query$,
    ).pipe(
      map(([manageApps, query]) => {
        const apps = [];
        // eslint-disable-next-line @typescript-eslint/no-unsafe-call
        apps.push(...this.manageAppsBackup.apps);
        apps.push(...manageApps.apps);
        this.manageAppsBackup.apps = apps;
        if (!manageApps.superAdmin && manageApps.studyPermissionCount < 2) {
          this.toastr.error(
            'This view displays app-wise enrollment if you manage multiple studies.',
          );
        }
        this.manageAppsBackup.apps = this.manageAppsBackup.apps.filter(
          (app: App) =>
            app.name?.toLowerCase().includes(query.toLowerCase()) ||
            app.customId?.toLowerCase().includes(query.toLowerCase()),
        );
        this.loadMoreEnabled =
          this.manageAppsBackup.apps.length % this.limit === 0 ? true : false;
        return this.manageAppsBackup;
      }),
    );
  }
}

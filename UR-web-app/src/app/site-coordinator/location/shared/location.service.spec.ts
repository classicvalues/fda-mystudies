import {TestBed, fakeAsync} from '@angular/core/testing';
import {HttpClientTestingModule} from '@angular/common/http/testing';
import {LocationService} from './location.service';
import {SiteCoordinatorModule} from '../../site-coordinator.module';
import {NO_ERRORS_SCHEMA} from '@angular/core';
import {RouterTestingModule} from '@angular/router/testing';
import {BsModalService, BsModalRef} from 'ngx-bootstrap/modal';
import {EntityService} from '../../../service/entity.service';
import {throwError, of} from 'rxjs';
import {Location} from '../shared/location.model';
import {ApiResponse} from 'src/app/entity/api.response.model';
describe('LocationService', () => {
  let locationService: LocationService;
  const expectedLocations = [
    {
      id: 2,
      customId: 'customid3',
      name: 'name -1-updated0',
      description: 'location-descp-updatedj',
      status: '1',
      studiesCount: 0,
      message: '',
      code: '',
    },
    {
      id: 3,
      customId: 'customid32',
      name: 'name -1 - updated000',
      description: 'location-descp-updated',
      status: '0',
      studiesCount: 0,
      message: '',
      code: '',
    },
  ];
  const expectedLocation: Location = {
    id: 0,
    status: '0',
    customId: 'customIDlocation',
    name: 'Location Name',
    description: 'location Decription',
    studiesCount: 0,
    message: '',
    code: '',
  };
  const expectedResponse = {
    id: 0,
    status: '0',
    customId: '',
    name: '',
    description: '',
    studiesCount: 0,
    message: '',
    code: '',
  };
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [
        HttpClientTestingModule,
        SiteCoordinatorModule,
        RouterTestingModule.withRoutes([]),
      ],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [LocationService, EntityService, BsModalService, BsModalRef],
    });
  });

  it('should be created', () => {
    const service: LocationService = TestBed.get(
      LocationService,
    ) as LocationService;
    expect(service).toBeTruthy();
  });

  it('should return expected Locations List', () => {
    const entityServicespy = jasmine.createSpyObj<EntityService<Location>>(
      'EntityService',
      ['getCollection'],
    );
    locationService = new LocationService(entityServicespy);

    entityServicespy.getCollection.and.returnValue(of(expectedLocations));
    locationService
      .getLocations()
      .subscribe(
        (Locations) =>
          expect(Locations).toEqual(expectedLocations, 'expected Locations'),
        fail,
      );

    expect(entityServicespy.getCollection.calls.count()).toBe(1, 'one call');
  });
  it('should return Locations list for the site creation', () => {
    const entityServicespy = jasmine.createSpyObj<EntityService<Location>>(
      'EntityService',
      ['getCollection'],
    );
    locationService = new LocationService(entityServicespy);

    entityServicespy.getCollection.and.returnValue(of(expectedLocations));
    locationService
      .getLocationsForSiteCreation('1')
      .subscribe(
        (Locations) =>
          expect(Locations).toEqual(expectedLocations, 'expected Locations'),
        fail,
      );

    expect(entityServicespy.getCollection.calls.count()).toBe(1, 'one call');
  });

  it('should post the  expected new Locations data', () => {
    const entityServicespyobj = jasmine.createSpyObj<EntityService<Location>>(
      'EntityService',
      ['post'],
    );
    locationService = new LocationService(entityServicespyobj);

    entityServicespyobj.post.and.returnValue(of(expectedResponse));

    locationService
      .addLocation(expectedLocation)
      .subscribe(
        (succesResponse: Location) =>
          expect(succesResponse).toEqual(
            expectedResponse,
            '{code:200,message:New location added successfully}',
          ),
        fail,
      );

    expect(entityServicespyobj.post.calls.count()).toBe(1, 'one call');
  });

  it('should return an error when the server returns a error status code', fakeAsync(() => {
    const entityServicespy = jasmine.createSpyObj<EntityService<Location>>(
      'EntityService',
      ['getCollection'],
    );
    locationService = new LocationService(entityServicespy);
    const errorResponse: ApiResponse = {
      message: 'User does not exist',
      code: 'MSG_013',
    };

    entityServicespy.getCollection.and.returnValue(throwError(errorResponse));

    locationService.getLocations().subscribe(
      () => fail('expected an error, not locations'),
      (error: ApiResponse) => {
        expect(error.message).toContain('User does not exist');
      },
    );
  }));
});
